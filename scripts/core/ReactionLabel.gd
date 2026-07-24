extends Label

# --- CONFIGURATION ---
const OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
const MODEL_NAME = "gemma3:4b" 

@onready var http_request: HTTPRequest = $HTTPRequest
@onready var equation_request: HTTPRequest = $EquationRequest

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
	
	# 2. Connect Buttons
	if close_button:
		if not close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.connect(_on_close_pressed)

	_setup_top_label_style()
	_setup_panel_style()


func _setup_top_label_style() -> void:
	# Configure Top HUD Notification Label (Centered, large font, high contrast black outline)
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	anchor_left = 0.15
	anchor_top = 0.03
	anchor_right = 0.85
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 80
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 26)
	add_theme_color_override("font_color", Color("ffffff"))
	add_theme_color_override("font_outline_color", Color("000000"))
	add_theme_constant_override("outline_size", 10)


func _setup_panel_style() -> void:
	if not detail_panel:
		return

	# Make detail_panel top level so it anchors to full CanvasLayer screen instead of parent Label 67px height
	detail_panel.top_level = true
	detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_panel.anchor_left = 0.15
	detail_panel.anchor_top = 0.12
	detail_panel.anchor_right = 0.85
	detail_panel.anchor_bottom = 0.88
	detail_panel.offset_left = 0
	detail_panel.offset_top = 0
	detail_panel.offset_right = 0
	detail_panel.offset_bottom = 0
	detail_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	detail_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	# Load custom parchment map texture
	var map_tex = null
	if ResourceLoader.exists("res://textures/parchment_map.png"):
		map_tex = ResourceLoader.load("res://textures/parchment_map.png")
	elif ResourceLoader.exists("res://textures/image.png"):
		map_tex = ResourceLoader.load("res://textures/image.png")
	if map_tex != null:
		var style := StyleBoxTexture.new()
		style.texture = map_tex
		style.content_margin_left = 45
		style.content_margin_right = 45
		style.content_margin_top = 45
		style.content_margin_bottom = 45
		detail_panel.add_theme_stylebox_override("panel", style)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("d6b88a")
		style.border_color = Color("4a2e18")
		style.set_border_width_all(5)
		style.set_corner_radius_all(14)
		style.content_margin_left = 35
		style.content_margin_right = 35
		style.content_margin_top = 35
		style.content_margin_bottom = 35
		detail_panel.add_theme_stylebox_override("panel", style)

	# RichTextLabel layout and ink text styling inside Parchment Map
	if detail_text:
		detail_text.set_anchors_preset(Control.PRESET_FULL_RECT)
		detail_text.anchor_left = 0.12
		detail_text.anchor_top = 0.10
		detail_text.anchor_right = 0.88
		detail_text.anchor_bottom = 0.82
		detail_text.offset_left = 0
		detail_text.offset_top = 0
		detail_text.offset_right = 0
		detail_text.offset_bottom = 0
		detail_text.bbcode_enabled = true
		detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_text.fit_content = false
		detail_text.scroll_following = false
		detail_text.add_theme_color_override("default_color", Color("1a0c04"))
		detail_text.add_theme_font_size_override("normal_font_size", 18)
		detail_text.add_theme_font_size_override("bold_font_size", 20)

	# Close Button styling inside Parchment Map
	if close_button:
		close_button.text = "✖ CLOSE ALCHEMY MAP"
		close_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		close_button.anchor_left = 0.58
		close_button.anchor_top = 0.83
		close_button.anchor_right = 0.88
		close_button.anchor_bottom = 0.92
		close_button.offset_left = 0
		close_button.offset_top = 0
		close_button.offset_right = 0
		close_button.offset_bottom = 0

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("5c1d00")
		btn_style.border_color = Color("8c3500")
		btn_style.set_border_width_all(2)
		btn_style.set_corner_radius_all(8)
		btn_style.content_margin_left = 14
		btn_style.content_margin_right = 14
		btn_style.content_margin_top = 8
		btn_style.content_margin_bottom = 8
		close_button.add_theme_stylebox_override("normal", btn_style)
		close_button.add_theme_color_override("font_color", Color("fff5ea"))


# --- SHOWING THE LABEL ---
func show_reaction(chemicals: String, flask_object = null):
	current_chemicals = chemicals
	target_flask = flask_object
	current_explanation_cache = "" # Reset cache
	
	# Show short notification HUD text
	text = current_chemicals + " -> ...\n[Press 'H' for Alchemy Map]"
	visible = true
	
	# Fetch Data (Try Cache First, then AI)
	fetch_reaction_data(chemicals)
	
	# Hide after 30 seconds (ONLY if player isn't reading details)
	await get_tree().create_timer(30.0).timeout
	if detail_panel and not detail_panel.visible:
		visible = false


# --- 1. GET DATA (Cache -> AI) ---
func fetch_reaction_data(chem_pair: String):
	if has_node("/root/SQLCache"):
		var parts = chem_pair.split("+")
		if parts.size() >= 2:
			var cached_data = get_node("/root/SQLCache").get_cached_reaction(parts[0].strip_edges(), parts[1].strip_edges())
			if cached_data:
				print("HIT CACHE! Loading from Database...")
				update_ui_from_data(cached_data["product"], cached_data["color"], cached_data["effect"])
				if "explanation" in cached_data:
					current_explanation_cache = cached_data["explanation"]
				return

	print("MISS CACHE! Asking AI...")
	
	var prompt = """
	Act as a chemistry database. Analyze this reaction: %s
	
	Return the output in this EXACT format (no other text):
	Product: [Chemical Formula of main product]
	Color: [Color of resulting liquid]
	Effect: [Visual effect: Bubbles, Smoke, Precipitate, or None]
	
	Example:
	Input: HCl + NaOH
	Product: NaCl + H2O
	Color: Clear
	Effect: None
	""" % chem_pair
	
	var ai_node = get_node_or_null("/root/AIService")
	if ai_node:
		ai_node.request_ai(prompt, func(response_text: String, success: bool):
			if success and response_text != "":
				var product = "..."
				var color = "Clear"
				var effect = "None"
				
				var lines = response_text.split("\n")
				for line in lines:
					line = line.strip_edges()
					if line.begins_with("Product:"):
						product = line.replace("Product:", "").strip_edges()
					elif line.begins_with("Color:"):
						color = line.replace("Color:", "").strip_edges()
					elif line.begins_with("Effect:"):
						effect = line.replace("Effect:", "").strip_edges()
				
				update_ui_from_data(product, color, effect)
				
				if has_node("/root/SQLCache"):
					var parts = current_chemicals.split("+")
					if parts.size() >= 2:
						get_node("/root/SQLCache").save_reaction(parts[0].strip_edges(), parts[1].strip_edges(), product, color, effect, "")
		, 0.1)


func update_ui_from_data(product, color, effect):
	text = current_chemicals + " -> " + product + "\n[Press 'H' for Alchemy Map]"
	if target_flask and target_flask.has_method("apply_reaction_effects"):
		target_flask.apply_reaction_effects(color, effect)


# --- 2. GET EXPLANATION (Press H) ---
func _input(event):
	if visible and detail_panel and not detail_panel.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_H:
			if current_explanation_cache != "":
				print("Showing Cached Explanation")
				show_detail_panel(current_explanation_cache)
			else:
				fetch_learn_more()


func fetch_learn_more():
	text = "Consulting AI Alchemist..."
	
	var prompt = """Explain the chemical reaction %s for a student simply and clearly.

EQUATION:
[Balanced chemical equation]

REACTION TYPE & ENERGY:
- Type: [Reaction type]
- Energy: [Exothermic or Endothermic]

KEY SCIENCE:
[2 simple sentences explaining why the reaction occurs]

OBSERVATIONS & SAFETY:
- Visuals: [Color change, gas, precipitate, or temperature]
- Safety: [Key safety precaution]
""" % current_chemicals
	
	var ai_node = get_node_or_null("/root/AIService")
	if ai_node:
		ai_node.request_ai(prompt, func(response_text: String, success: bool):
			if success and response_text != "":
				show_detail_panel(response_text)
			else:
				detail_text.text = "Error fetching explanation."
				detail_panel.visible = true
		, 0.2, 60)


func show_detail_panel(content: String):
	detail_text.text = _format_funky_bbcode(content)
	detail_panel.visible = true
	text = "" 
	print("Detail Panel Opened!")


func _format_funky_bbcode(text_content: String) -> String:
	var result = text_content
	
	# Strip raw markdown header hashes
	result = result.replace("### ", "").replace("## ", "").replace("# ", "")
	
	# Add prominent centered header title
	var formatted = "[center][font_size=26][b][color=#5c1d00]📜 ALCHEMY REACTION RECORD[/color][/b][/font_size][/center]\n\n"
	
	# Format section headers with bold funky colors
	result = result.replace("EQUATION:", "[font_size=22][b][color=#7a0000]📜 BALANCED CHEMICAL EQUATION[/color][/b][/font_size]")
	result = result.replace("REACTION TYPE & ENERGY:", "[font_size=22][b][color=#4a1500]⚡ REACTION CLASSIFICATION & ENERGY[/color][/b][/font_size]")
	result = result.replace("REACTION CLASSIFICATION & THERMODYNAMICS:", "[font_size=22][b][color=#4a1500]⚡ REACTION CLASSIFICATION & ENERGY[/color][/b][/font_size]")
	result = result.replace("KEY SCIENCE:", "[font_size=22][b][color=#0f380f]🔬 KEY SCIENTIFIC MECHANISM[/color][/b][/font_size]")
	result = result.replace("KEY SCIENTIFIC MECHANISM:", "[font_size=22][b][color=#0f380f]🔬 KEY SCIENTIFIC MECHANISM[/color][/b][/font_size]")
	result = result.replace("OBSERVATIONS & SAFETY:", "[font_size=22][b][color=#5c1d00]👁️ LAB OBSERVATIONS & SAFETY[/color][/b][/font_size]")
	result = result.replace("LABORATORY OBSERVATIONS & SAFETY:", "[font_size=22][b][color=#5c1d00]👁️ LAB OBSERVATIONS & SAFETY[/color][/b][/font_size]")

	# Format bold inline labels
	result = result.replace("**", "")
	result = result.replace("Type:", "[color=#4a1500][b]Type:[/b][/color]")
	result = result.replace("Energy:", "[color=#7a0000][b]Energy:[/b][/color]")
	result = result.replace("Visuals:", "[color=#0f380f][b]Visuals:[/b][/color]")
	result = result.replace("Safety:", "[color=#5c1d00][b]Safety:[/b][/color]")

	return formatted + result


func _on_close_pressed():
	detail_panel.visible = false
	visible = false
