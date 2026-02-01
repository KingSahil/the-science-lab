extends Label

# --- CONFIGURATION ---
const OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
# Make sure this matches your model exactly!
const MODEL_NAME = "gemma3:4b" 

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var equation_request: HTTPRequest = $EquationRequest

# --- NODE PATHS ---
# We use get_node_or_null to be safe. 
# IF THIS FAILS: Drag the 'DetailPanel' node from your scene into this script to fix the path.
@onready var detail_panel: Panel = $DetailPanel
@onready var detail_text: RichTextLabel = $DetailPanel/RichTextLabel
@onready var close_button: Button = $DetailPanel/CloseButton

var current_chemicals = ""
var target_flask = null 
var current_explanation_cache = "" # Stores explanation if loaded from DB

func _ready():
	# 1. Hide everything at start
	if detail_panel:
		detail_panel.visible = false
	visible = false
	
	# 2. Connect Buttons and Signals
	if close_button:
		if not close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.connect(_on_close_pressed)
	
	if http_request:
		http_request.request_completed.connect(_on_explanation_response)
	if equation_request:
		equation_request.request_completed.connect(_on_reaction_data_response)

# --- SHOWING THE LABEL ---
func show_reaction(chemicals: String, flask_object = null):
	current_chemicals = chemicals
	target_flask = flask_object
	current_explanation_cache = "" # Reset cache
	
	# Show the short "Press H" text
	text = current_chemicals + " -> ...\n[Press 'H' to Learn More]"
	visible = true
	
	# Fetch Data (Try Cache First, then AI)
	fetch_reaction_data(chemicals)
	
	# Hide after 30 seconds (ONLY if the player isn't reading details)
	await get_tree().create_timer(30.0).timeout
	if detail_panel and not detail_panel.visible:
		visible = false

# --- 1. GET DATA (Cache -> AI) ---
func fetch_reaction_data(chem_pair: String):
	# A. Try Loading from SQL Cache (Check if Autoload exists)
	if has_node("/root/SQLCache"):
		var parts = chem_pair.split("+")
		if parts.size() >= 2:
			var cached_data = get_node("/root/SQLCache").get_cached_reaction(parts[0].strip_edges(), parts[1].strip_edges())
			
			if cached_data:
				print("HIT CACHE! Loading from Database...")
				update_ui_from_data(cached_data["product"], cached_data["color"], cached_data["effect"])
				if "explanation" in cached_data:
					current_explanation_cache = cached_data["explanation"]
				return # Stop here, no need to ask Gemma!

	# B. Cache Miss? Ask Gemma
	print("MISS CACHE! Asking Gemma...")
	
	var prompt = """
	Act as a chemistry database. Analyze this reaction: %s
	
	Return the output in this EXACT format (no other text):
	Product: [Chemical Formula of the main product]
	Color: [The color of the resulting liquid, e.g., Pink, Clear, Blue, White]
	Effect: [Visual effect, one of: Bubbles, Smoke, Precipitate, None]
	
	Example:
	Input: HCl + NaOH
	Product: NaCl + H2O
	Color: Clear
	Effect: None
	""" % chem_pair
	
	var body_data = {
		"model": MODEL_NAME,
		"prompt": prompt,
		"stream": false,
		"temperature": 0.1
	}
	
	equation_request.request(OLLAMA_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body_data))

func _on_reaction_data_response(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and "response" in json:
			var full_response = json["response"]
			
			var product = "..."
			var color = "Clear"
			var effect = "None"
			
			# Parse line by line
			var lines = full_response.split("\n")
			for line in lines:
				line = line.strip_edges()
				if line.begins_with("Product:"):
					product = line.replace("Product:", "").strip_edges()
				elif line.begins_with("Color:"):
					color = line.replace("Color:", "").strip_edges()
				elif line.begins_with("Effect:"):
					effect = line.replace("Effect:", "").strip_edges()
			
			# Update UI & Visuals
			update_ui_from_data(product, color, effect)
			
			# Save partial data to Cache
			if has_node("/root/SQLCache"):
				var parts = current_chemicals.split("+")
				if parts.size() >= 2:
					get_node("/root/SQLCache").save_reaction(parts[0].strip_edges(), parts[1].strip_edges(), product, color, effect, "")

# Helper to update UI (Used by both Cache and AI)
func update_ui_from_data(product, color, effect):
	text = current_chemicals + " -> " + product + "\n[Press 'H' to Learn More]"
	
	if target_flask and target_flask.has_method("apply_reaction_effects"):
		target_flask.apply_reaction_effects(color, effect)

# --- 2. GET EXPLANATION (Manual H) ---
func _input(event):
	# Listen for 'H' key only if the label is up and panel is down
	if visible and detail_panel and not detail_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_H:
			# Check if we already have it in cache
			if current_explanation_cache != "":
				print("Showing Cached Explanation")
				show_detail_panel(current_explanation_cache)
			else:
				fetch_learn_more()

func fetch_learn_more():
	text = "Asking Gemma for details..."
	var prompt = "Explain the reaction: " + current_chemicals + " simply."
	var body_data = { "model": MODEL_NAME, "prompt": prompt, "stream": false }
	http_request.request(OLLAMA_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body_data))

func _on_explanation_response(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and "response" in json:
			var explanation = json["response"]
			show_detail_panel(explanation)
			
			# Update Cache with the new explanation!
			# Note: This logic assumes your save_reaction handles updates or you don't mind duplicates/overwrites
			# For a simple project, saving again is fine.
			if has_node("/root/SQLCache"):
				pass 
	else:
		detail_text.text = "Error fetching explanation."
		detail_panel.visible = true

func show_detail_panel(content: String):
	# 1. Set the long text inside the popup
	detail_text.text = content
	
	# 2. Show the popup panel
	detail_panel.visible = true
	
	# 3. Clear the main label text so it doesn't block view, BUT keep 'visible=true' 
	#    so the node stays active to handle input/rendering children.
	text = "" 
	
	print("Detail Panel Opened!")

func _on_close_pressed():
	# Close everything
	detail_panel.visible = false
	visible = false
