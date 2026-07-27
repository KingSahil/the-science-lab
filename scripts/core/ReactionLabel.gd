extends Label

# --- CONFIGURATION ---
const OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
const MODEL_NAME = "gemma4:4b"

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

	# Make detail_panel top level so it anchors to full CanvasLayer screen instead of parent Label height
	detail_panel.top_level = true
	detail_panel.clip_contents = true
	detail_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	detail_panel.anchor_left = 0.14
	detail_panel.anchor_top = 0.10
	detail_panel.anchor_right = 0.86
	detail_panel.anchor_bottom = 0.90
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
		style.content_margin_left = 50
		style.content_margin_right = 50
		style.content_margin_top = 50
		style.content_margin_bottom = 50
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
		detail_text.anchor_left = 0.14
		detail_text.anchor_top = 0.13
		detail_text.anchor_right = 0.855
		detail_text.anchor_bottom = 0.79
		detail_text.offset_left = 0
		detail_text.offset_top = 0
		detail_text.offset_right = 0
		detail_text.offset_bottom = 0
		detail_text.bbcode_enabled = true
		detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_text.fit_content = false
		detail_text.scroll_active = true
		detail_text.scroll_following = false
		detail_text.clip_contents = true
		detail_text.add_theme_color_override("default_color", Color("1a0c04"))
		detail_text.add_theme_font_size_override("normal_font_size", 18)
		detail_text.add_theme_font_size_override("bold_font_size", 20)

		# Custom Gamified Curved Parchment Scrollbar Styling
		var v_scroll: VScrollBar = detail_text.get_v_scroll_bar()
		if v_scroll:
			v_scroll.custom_minimum_size.x = 14
			
			# 1. Track / Channel Style
			var track_style := StyleBoxFlat.new()
			track_style.bg_color = Color("381f10a8") # Warm translucent dark leather
			track_style.border_color = Color("5c3316")
			track_style.set_border_width_all(2)
			track_style.set_corner_radius_all(7)
			track_style.content_margin_left = 2
			track_style.content_margin_right = 2
			v_scroll.add_theme_stylebox_override("scroll", track_style)
			
			# 2. Grabber / Thumb Style (Normal)
			var grabber_style := StyleBoxFlat.new()
			grabber_style.bg_color = Color("7a3e19") # Parchment leather brown
			grabber_style.border_color = Color("c78a3b") # Gamified gold/bronze trim
			grabber_style.set_border_width_all(2)
			grabber_style.set_corner_radius_all(9) # Curved gamified capsule shape
			v_scroll.add_theme_stylebox_override("grabber", grabber_style)
			
			# 3. Grabber Hover State
			var grabber_hover := StyleBoxFlat.new()
			grabber_hover.bg_color = Color("9e521d") # Bright warm amber glow
			grabber_hover.border_color = Color("e3aa52") # Bright gold trim
			grabber_hover.set_border_width_all(2)
			grabber_hover.set_corner_radius_all(9)
			v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_hover)
			
			# 4. Grabber Pressed State
			var grabber_pressed := StyleBoxFlat.new()
			grabber_pressed.bg_color = Color("5c2a0c") # Deep mahogany
			grabber_pressed.border_color = Color("a86e28")
			grabber_pressed.set_border_width_all(2)
			grabber_pressed.set_corner_radius_all(9)
			v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_pressed)
			
			# Also set v_scrollbar theme overrides directly on RichTextLabel as fallback
			detail_text.add_theme_stylebox_override("v_scrollbar_scroll", track_style)
			detail_text.add_theme_stylebox_override("v_scrollbar_grabber", grabber_style)
			detail_text.add_theme_stylebox_override("v_scrollbar_grabber_highlight", grabber_hover)
			detail_text.add_theme_stylebox_override("v_scrollbar_grabber_pressed", grabber_pressed)

	# Close Button styling inside Parchment Map
	if close_button:
		close_button.text = "✖ CLOSE ALCHEMY MAP"
		close_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		close_button.anchor_left = 0.56
		close_button.anchor_top = 0.82
		close_button.anchor_right = 0.84
		close_button.anchor_bottom = 0.90
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
			if current_explanation_cache != "" and ("VISUAL" in current_explanation_cache or "DIAGRAM" in current_explanation_cache):
				print("Showing Cached Explanation")
				show_detail_panel(current_explanation_cache)
			else:
				fetch_learn_more()


func fetch_learn_more():
	text = "Consulting AI Alchemist..."
	
	var prompt = """Explain the chemical reaction %s for a beginner chemistry student.

CRITICAL FORMATTING RULES:
1. DO NOT WRITE DENSE PARAGRAPHS. Write strictly concise single lines (one sentence per line with a bullet point '- ').
2. Use SUPER SIMPLE beginner-friendly language with fun analogies (e.g. 'like magnet attraction', 'swapping dance partners').
3. Include an easy-to-read ASCII art diagram showing what happens to the molecules visually!

Format your response under these EXACT section titles:

EQUATION:
- Formula: [Balanced chemical equation with common names in parentheses]

VISUAL REACTION DIAGRAM:
[Easy-to-understand ASCII text diagram using arrows and boxes, e.g.:
[Molecule A] + [Molecule B] ---> [Product C] + [Product D]
      |               |
      v               v
  (Bond Breaks)   (New Bond Forms)
]

REACTION TYPE & HEAT:
- Type: [Simple reaction classification e.g. Acid + Base Neutralization, Synthesis, Decomposition]
- Energy: [Simple explanation of whether it gets HOT (Exothermic) or COLD (Endothermic)]

HOW IT WORKS (STEP-BY-STEP):
- Step 1: [Short single-line step with simple analogy]
- Step 2: [Short single-line step explaining bond breaking/forming]
- Step 3: [Short single-line step showing the final stable result]

LAB OBSERVATIONS & SAFETY:
- Visuals: [What you see with your eyes: Bubbles, color shift, heat, or precipitate]
- Safety: [Crucial safety rule in 1 simple line]

FUN FACT & REAL WORLD:
- Uses: [1 fun real-world example of where this reaction occurs]
""" % current_chemicals
	
	var ai_node = get_node_or_null("/root/AIService")
	if ai_node:
		ai_node.request_ai(prompt, func(response_text: String, success: bool):
			if success and response_text != "":
				current_explanation_cache = response_text
				show_detail_panel(response_text)
				
				if has_node("/root/SQLCache"):
					var parts = current_chemicals.split("+")
					if parts.size() >= 2:
						get_node("/root/SQLCache").update_reaction_explanation(parts[0].strip_edges(), parts[1].strip_edges(), response_text)
			else:
				detail_text.text = "Error fetching explanation."
				detail_panel.visible = true
		, 0.2, 600)


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
	var formatted = "[center][font_size=24][b][color=#5c1d00]📜 ALCHEMY REACTION RECORD[/color][/b][/font_size][/center]\n\n"
	
	# Format section headers with bold funky colors
	result = result.replace("EQUATION:", "[font_size=20][b][color=#7a0000]📜 BALANCED CHEMICAL EQUATION[/color][/b][/font_size]")
	result = result.replace("VISUAL REACTION DIAGRAM:", "[font_size=20][b][color=#5c1d00]🎨 VISUAL REACTION DIAGRAM[/color][/b][/font_size]")
	result = result.replace("REACTION TYPE & HEAT:", "[font_size=20][b][color=#4a1500]⚡ REACTION TYPE & HEAT[/color][/b][/font_size]")
	result = result.replace("REACTION TYPE & ENERGY:", "[font_size=20][b][color=#4a1500]⚡ REACTION TYPE & HEAT[/color][/b][/font_size]")
	result = result.replace("REACTION TYPE & THERMODYNAMICS:", "[font_size=20][b][color=#4a1500]⚡ REACTION TYPE & HEAT[/color][/b][/font_size]")
	result = result.replace("HOW IT WORKS (STEP-BY-STEP):", "[font_size=20][b][color=#0f380f]🔬 HOW IT WORKS (STEP-BY-STEP)[/color][/b][/font_size]")
	result = result.replace("KEY SCIENTIFIC MECHANISM:", "[font_size=20][b][color=#0f380f]🔬 HOW IT WORKS (STEP-BY-STEP)[/color][/b][/font_size]")
	result = result.replace("LAB OBSERVATIONS & SAFETY:", "[font_size=20][b][color=#5c1d00]👁️ LAB OBSERVATIONS & SAFETY[/color][/b][/font_size]")
	result = result.replace("WHAT YOU SEE & SAFETY:", "[font_size=20][b][color=#5c1d00]👁️ LAB OBSERVATIONS & SAFETY[/color][/b][/font_size]")
	result = result.replace("FUN FACT & REAL WORLD:", "[font_size=20][b][color=#2b4c10]💡 FUN FACT & REAL-WORLD USE[/color][/b][/font_size]")
	result = result.replace("REAL-WORLD APPLICATIONS & ALCHEMY:", "[font_size=20][b][color=#2b4c10]💡 FUN FACT & REAL-WORLD USE[/color][/b][/font_size]")

	# Format bold inline labels
	result = result.replace("**", "")
	result = result.replace("Formula:", "[color=#7a0000][b]Formula:[/b][/color]")
	result = result.replace("Type:", "[color=#4a1500][b]Type:[/b][/color]")
	result = result.replace("Energy:", "[color=#7a0000][b]Energy:[/b][/color]")
	result = result.replace("Heat:", "[color=#7a0000][b]Heat:[/b][/color]")
	result = result.replace("Step 1:", "[color=#0f380f][b]Step 1:[/b][/color]")
	result = result.replace("Step 2:", "[color=#0f380f][b]Step 2:[/b][/color]")
	result = result.replace("Step 3:", "[color=#0f380f][b]Step 3:[/b][/color]")
	result = result.replace("Visuals:", "[color=#0f380f][b]Visuals:[/b][/color]")
	result = result.replace("Safety:", "[color=#5c1d00][b]Safety:[/b][/color]")
	result = result.replace("Uses:", "[color=#2b4c10][b]Uses:[/b][/color]")
	result = result.replace("Fact:", "[color=#2b4c10][b]Fact:[/b][/color]")

	return formatted + result


func _on_close_pressed():
	detail_panel.visible = false
	visible = false
