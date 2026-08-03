extends CanvasLayer

const InventoryScript = preload("res://addons/gloot/core/inventory.gd")
const ItemSlotScript = preload("res://addons/gloot/core/item_slot.gd")
const FlaskScene = preload("res://scenes/flasks/flask.tscn")

const MAP_MAHOGANY   := Color("3b1d0c")
const MAP_LEATHER    := Color("5c2a0c")
const MAP_GOLD       := Color("c78a3b")
const MAP_GOLD_BRIGHT:= Color("e3aa52")
const MAP_INK_DARK   := Color("1a0c04")
const MAP_INK_HEADER := Color("4a1700")
const MAP_MUTED      := Color("4a2810")
const MAP_CREAM      := Color("fff5ea")
const MAP_PARCHMENT  := Color("d6b88a")

const NAVY := MAP_MAHOGANY
const NAVY_LIGHT := MAP_LEATHER
const BLUE := MAP_GOLD
const CYAN := MAP_INK_HEADER
const TEXT := MAP_INK_DARK
const MUTED := MAP_MUTED

var _inventory
var _protoset: JSON
var _quick_slots: Array = []
var _selected_item = null
var _active_slot := 0
var _active_category := "Chemicals"
var _player_controller
var _restore_can_move := true
var _restore_unhandled_input := true

var _ui: Control
var _search: LineEdit
var _grid: GridContainer
var _empty_state: Label
var _storage_header: Label
var _detail_icon
var _detail_name: Label
var _detail_formula: Label
var _detail_description: Label
var _detail_quantity: Label
var _equip_button: Button
var _hotbar: HBoxContainer
var _gameplay_hotbar: HBoxContainer
var _tab_buttons: Dictionary = {}
var _held_flask: Node3D
var _ai_status_label: Label
var _is_fetching_ai := false
var _search_timer: Timer



class LabItemIcon extends Control:
	var kind := "chemical"
	var accent := Color("8bf4ff")

	func _init() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE

	func set_item_data(new_kind: String, new_accent: Color) -> void:
		kind = new_kind
		accent = new_accent
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var line := MAP_MAHOGANY
		if kind == "chemical":
			var neck := Rect2(center.x - size.x * 0.11, size.y * 0.08, size.x * 0.22, size.y * 0.28)
			var body := PackedVector2Array([
				Vector2(center.x - size.x * 0.11, size.y * 0.28), Vector2(center.x + size.x * 0.11, size.y * 0.28),
				Vector2(center.x + size.x * 0.34, size.y * 0.82), Vector2(center.x + size.x * 0.22, size.y * 0.94),
				Vector2(center.x - size.x * 0.22, size.y * 0.94), Vector2(center.x - size.x * 0.34, size.y * 0.82)
			])
			draw_rect(neck, Color(0.85, 0.97, 1.0, 0.34), true)
			draw_colored_polygon(body, Color(0.78, 0.94, 1.0, 0.25))
			draw_polyline(body, line, 2.0, true)
			draw_rect(Rect2(center.x - size.x * 0.27, size.y * 0.66, size.x * 0.54, size.y * 0.22), accent, true)
			draw_line(Vector2(center.x - size.x * 0.27, size.y * 0.66), Vector2(center.x + size.x * 0.27, size.y * 0.66), line, 1.4)
		elif kind == "beaker":
			draw_line(Vector2(size.x * 0.25, size.y * 0.15), Vector2(size.x * 0.75, size.y * 0.15), line, 2.5)
			draw_rect(Rect2(size.x * 0.3, size.y * 0.17, size.x * 0.4, size.y * 0.65), Color(0.72, 0.93, 1.0, 0.14), true)
			draw_line(Vector2(size.x * 0.3, size.y * 0.17), Vector2(size.x * 0.3, size.y * 0.82), line, 2.0)
			draw_line(Vector2(size.x * 0.7, size.y * 0.17), Vector2(size.x * 0.7, size.y * 0.82), line, 2.0)
			draw_line(Vector2(size.x * 0.3, size.y * 0.82), Vector2(size.x * 0.7, size.y * 0.82), line, 2.0)
			draw_rect(Rect2(size.x * 0.31, size.y * 0.58, size.x * 0.38, size.y * 0.22), accent, true)
		elif kind == "flask":
			var flask := PackedVector2Array([
				Vector2(size.x * 0.42, size.y * 0.1), Vector2(size.x * 0.58, size.y * 0.1), Vector2(size.x * 0.58, size.y * 0.36),
				Vector2(size.x * 0.82, size.y * 0.82), Vector2(size.x * 0.7, size.y * 0.94), Vector2(size.x * 0.3, size.y * 0.94),
				Vector2(size.x * 0.18, size.y * 0.82), Vector2(size.x * 0.42, size.y * 0.36)
			])
			draw_colored_polygon(flask, Color(0.7, 0.93, 1.0, 0.16))
			draw_polyline(flask, line, 2.0, true)
			draw_rect(Rect2(size.x * 0.25, size.y * 0.69, size.x * 0.5, size.y * 0.16), accent, true)
		elif kind == "goggles":
			draw_arc(Vector2(size.x * 0.31, size.y * 0.5), size.x * 0.2, 0.0, TAU, 24, line, 2.2)
			draw_arc(Vector2(size.x * 0.69, size.y * 0.5), size.x * 0.2, 0.0, TAU, 24, line, 2.2)
			draw_line(Vector2(size.x * 0.48, size.y * 0.5), Vector2(size.x * 0.52, size.y * 0.5), line, 2.2)
			draw_line(Vector2(size.x * 0.1, size.y * 0.5), Vector2(size.x * 0.02, size.y * 0.5), accent, 2.2)
			draw_line(Vector2(size.x * 0.9, size.y * 0.5), Vector2(size.x * 0.98, size.y * 0.5), accent, 2.2)
		elif kind == "manual":
			draw_rect(Rect2(size.x * 0.25, size.y * 0.1, size.x * 0.5, size.y * 0.8), Color(0.8, 0.95, 1.0, 0.22), true)
			draw_rect(Rect2(size.x * 0.25, size.y * 0.1, size.x * 0.5, size.y * 0.8), line, false, 2.0)
			for y in [0.35, 0.49, 0.63]:
				draw_line(Vector2(size.x * 0.35, size.y * y), Vector2(size.x * 0.65, size.y * y), accent, 2.0)
		else:
			draw_line(Vector2(size.x * 0.5, size.y * 0.13), Vector2(size.x * 0.5, size.y * 0.78), line, 3.0)
			draw_circle(Vector2(size.x * 0.5, size.y * 0.84), size.x * 0.1, accent)


class LabInventoryUI extends Control:
	var inventory_script = null

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("source")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if !(data is Dictionary) or inventory_script == null:
			return
		var src = data.get("source", "")
		if src == "quick_slot":
			inventory_script._unequip_slot(data.get("slot_index", -1))


class LabStorageGridArea extends ScrollContainer:
	var inventory_script = null

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("source")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if data is Dictionary and data.get("source") == "quick_slot" and inventory_script != null:
			inventory_script._unequip_slot(data.get("slot_index", -1))


class LabItemCard extends Button:
	var item = null
	var inventory_script = null

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if item == null or inventory_script == null:
			return null
		var preview = inventory_script._create_drag_preview(item)
		set_drag_preview(preview)
		return {
			"source": "storage",
			"item": item
		}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("source")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if !(data is Dictionary) or inventory_script == null:
			return
		var src = data.get("source", "")
		if src == "quick_slot":
			inventory_script._unequip_slot(data.get("slot_index", -1))
		elif src == "storage" and data.get("item") != null:
			inventory_script._select_item(data.get("item"))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click and event.pressed:
			if item != null and inventory_script != null:
				var slot_idx = inventory_script._slot_index_for_item(item)
				if slot_idx >= 0:
					inventory_script._select_slot(slot_idx)
				else:
					inventory_script._equip_item_to_slot(item, inventory_script._target_slot_index())
				accept_event()


class LabSlotButton extends Button:
	var slot_index: int = -1
	var item = null
	var inventory_script = null

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if item == null or inventory_script == null:
			return null
		var preview = inventory_script._create_drag_preview(item)
		set_drag_preview(preview)
		return {
			"source": "quick_slot",
			"slot_index": slot_index,
			"item": item
		}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("source")

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if !(data is Dictionary) or inventory_script == null:
			return
		var src = data.get("source", "")
		if src == "storage":
			inventory_script._equip_item_to_slot(data.get("item"), slot_index)
		elif src == "quick_slot":
			inventory_script._swap_quick_slots(data.get("slot_index", -1), slot_index)


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_search_timer = Timer.new()
	_search_timer.one_shot = true
	_search_timer.wait_time = 0.45
	_search_timer.timeout.connect(_on_search_timer_timeout)
	add_child(_search_timer)
	
	_protoset = _create_protoset()
	_create_inventory()
	_build_ui()
	_player_controller = get_parent().get_node_or_null("ProtoController")
	if _player_controller != null:
		if _player_controller.has_signal("object_dropped") and not _player_controller.object_dropped.is_connected(_on_player_object_dropped):
			_player_controller.object_dropped.connect(_on_player_object_dropped)
		if _player_controller.has_signal("object_picked") and not _player_controller.object_picked.is_connected(_on_player_object_picked):
			_player_controller.object_picked.connect(_on_player_object_picked)
	_ui.hide()
	_select_slot(_active_slot)



func _create_protoset() -> JSON:
	var protoset := JSON.new()
	var definitions := {
		"naoh": {"name": "Sodium Hydroxide", "formula": "NaOH", "category": "Chemicals", "description": "A strong base for neutralization experiments.", "kind": "chemical", "accent": "#79e9ff"},
		"hcl": {"name": "Hydrochloric Acid", "formula": "HCl", "category": "Chemicals", "description": "A clear acid for controlled lab reactions.", "kind": "chemical", "accent": "#c8f1ff"},
		"caso4": {"name": "Calcium Sulfate", "formula": "CaSO₄", "category": "Chemicals", "description": "A mineral reagent for precipitation tests.", "kind": "chemical", "accent": "#f4e8ad"},
		"cuo": {"name": "Copper(II) Oxide", "formula": "CuO", "category": "Chemicals", "description": "A copper compound for heating experiments.", "kind": "chemical", "accent": "#d9a1ff"},
		"cuso4": {"name": "Copper(II) Sulfate", "formula": "CuSO₄", "category": "Chemicals", "description": "A blue copper salt for precipitation reactions.", "kind": "chemical", "accent": "#4a90e2"},
		"beaker": {"name": "Glass Beaker", "formula": "BEAKER", "category": "Equipment", "description": "Heat-safe vessel for mixing solutions.", "kind": "beaker", "accent": "#67dfff"},
		"flask": {"name": "Erlenmeyer Flask", "formula": "FLASK", "category": "Equipment", "description": "Stable reaction flask for liquid experiments.", "kind": "flask", "accent": "#8beeff"},
		"goggles": {"name": "Safety Goggles", "formula": "SAFETY", "category": "Equipment", "description": "Protective eyewear for active experiments.", "kind": "goggles", "accent": "#74c8ff"},
		"stirrer": {"name": "Glass Stirrer", "formula": "STIRRER", "category": "Equipment", "description": "Use to gently mix a solution.", "kind": "stirrer", "accent": "#8ff8ff"},
		"lab_safety": {"name": "Lab Safety Manual", "formula": "SAFETY", "category": "Manuals", "description": "Core field guidance for every scientist.", "kind": "manual", "accent": "#8ecfff"},
		"acid_base": {"name": "Acid & Base Basics", "formula": "REFERENCE", "category": "Manuals", "description": "Reference notes for neutralization reactions.", "kind": "manual", "accent": "#aadfff"}
	}
	protoset.parse(JSON.stringify(definitions))
	return protoset


func _create_inventory() -> void:
	_inventory = InventoryScript.new()
	_inventory.name = "ScienceInventory"
	_inventory.protoset = _protoset
	add_child(_inventory)
	for prototype_id in ["naoh", "hcl", "caso4", "cuo", "cuso4"]:
		_inventory.create_and_add_item(prototype_id)
	
	_load_cached_chemicals_from_db()

	for index in 6:
		var item_slot = ItemSlotScript.new()
		item_slot.name = "QuickSlot%d" % (index + 1)
		item_slot.protoset = _protoset
		add_child(item_slot)
		_quick_slots.append(item_slot)
	_quick_slots[0].equip(_inventory.get_item_with_prototype_id("hcl"))
	_quick_slots[1].equip(_inventory.get_item_with_prototype_id("naoh"))
	_selected_item = _quick_slots[0].get_item()



func _build_ui() -> void:
	_build_gameplay_hotbar()
	var main_ui := LabInventoryUI.new()
	main_ui.name = "InventoryUI"
	main_ui.inventory_script = self
	main_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui = main_ui
	add_child(_ui)

	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.03, 0.01, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	_ui.add_child(margin)

	var terminal := PanelContainer.new()
	var map_tex = null
	if ResourceLoader.exists("res://textures/parchment_map.png"):
		map_tex = ResourceLoader.load("res://textures/parchment_map.png")
	elif ResourceLoader.exists("res://textures/image.png"):
		map_tex = ResourceLoader.load("res://textures/image.png")
		
	if map_tex != null:
		var style := StyleBoxTexture.new()
		style.texture = map_tex
		style.content_margin_left = 135
		style.content_margin_right = 135
		style.content_margin_top = 85
		style.content_margin_bottom = 85
		terminal.add_theme_stylebox_override("panel", style)
	else:
		terminal.add_theme_stylebox_override("panel", _panel_style(MAP_PARCHMENT, MAP_MAHOGANY, 4, 14))
	margin.add_child(terminal)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 16)
	inner.add_theme_constant_override("margin_top", 12)
	inner.add_theme_constant_override("margin_right", 16)
	inner.add_theme_constant_override("margin_bottom", 12)
	terminal.add_child(inner)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	inner.add_child(layout)
	_build_header(layout)
	_build_toolbar(layout)
	_build_body(layout)
	_build_footer(layout)
	_refresh_all()


func _build_gameplay_hotbar() -> void:
	var hud := Control.new()
	hud.name = "GameplayHotbar"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var center := CenterContainer.new()
	center.anchor_left = 0.5
	center.anchor_right = 0.5
	center.anchor_top = 1.0
	center.anchor_bottom = 1.0
	center.offset_left = -330.0
	center.offset_right = 330.0
	center.offset_top = -102.0
	center.offset_bottom = -24.0
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("2c150bb8"), MAP_GOLD, 2, 10))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)
	_gameplay_hotbar = HBoxContainer.new()
	_gameplay_hotbar.add_theme_constant_override("separation", 8)
	margin.add_child(_gameplay_hotbar)


func _build_header(parent: Container) -> void:
	var header := HBoxContainer.new()
	parent.add_child(header)
	var title := _label("📜 ALCHEMY FIELD INVENTORY", 24, MAP_INK_HEADER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var status := _label("REAGENTS READY", 13, MAP_MUTED)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(status)
	var close := Button.new()
	close.text = "✖ CLOSE  [I]"
	close.add_theme_font_size_override("font_size", 13)
	_apply_button_style(close, MAP_MAHOGANY, MAP_GOLD, MAP_CREAM)
	close.pressed.connect(_close_inventory)
	header.add_child(close)


func _build_toolbar(parent: Container) -> void:
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 14)
	parent.add_child(toolbar)
	_search = LineEdit.new()
	_search.placeholder_text = "Search any chemical (e.g. Caffeine, Acetone, Nitroglycerin)..."
	_search.clear_button_enabled = true
	_search.custom_minimum_size = Vector2(0, 43)
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.add_theme_font_size_override("font_size", 16)
	_search.add_theme_color_override("font_color", MAP_INK_DARK)
	_search.add_theme_color_override("font_placeholder_color", MAP_MUTED)
	_search.add_theme_stylebox_override("normal", _panel_style(Color("ebdcc4"), MAP_LEATHER, 1, 8))
	_search.add_theme_stylebox_override("focus", _panel_style(Color("f7ebd8"), MAP_GOLD, 2, 8))
	_search.text_changed.connect(func(value: String): _on_search_text_changed(value))
	_search.text_submitted.connect(func(query: String): _on_search_submitted(query))
	toolbar.add_child(_search)
	for category in ["Chemicals", "Equipment", "Manuals"]:
		var tab := Button.new()
		tab.text = category.to_upper()
		tab.custom_minimum_size = Vector2(112, 43)
		tab.add_theme_font_size_override("font_size", 13)
		tab.pressed.connect(_set_category.bind(category))
		toolbar.add_child(tab)
		_tab_buttons[category] = tab


func _build_body(parent: Container) -> void:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	parent.add_child(body)
	var inventory_column := VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_column.add_theme_constant_override("separation", 9)
	body.add_child(inventory_column)
	var grid_header := HBoxContainer.new()
	inventory_column.add_child(grid_header)
	_storage_header = _label("CHEMICAL STORAGE", 15, MAP_INK_HEADER)
	_storage_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_header.add_child(_storage_header)
	var hint := _label("Click an item to inspect", 13, MAP_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid_header.add_child(hint)
	var scroll := LabStorageGridArea.new()
	scroll.inventory_script = self
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_column.add_child(scroll)
	var grid_holder := VBoxContainer.new()
	grid_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_holder)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	grid_holder.add_child(_grid)
	_empty_state = _label("No matching items in this category.", 16, MAP_MUTED)
	_empty_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_state.custom_minimum_size = Vector2(0, 60)
	grid_holder.add_child(_empty_state)

	_ai_status_label = _label("", 13, MAP_INK_HEADER)
	_ai_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ai_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid_holder.add_child(_ai_status_label)

	var detail := PanelContainer.new()
	detail.custom_minimum_size = Vector2(285, 0)
	detail.add_theme_stylebox_override("panel", _panel_style(Color("ebdcc4"), MAP_MAHOGANY, 2, 10))
	body.add_child(detail)
	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 18)
	detail_margin.add_theme_constant_override("margin_top", 17)
	detail_margin.add_theme_constant_override("margin_right", 18)
	detail_margin.add_theme_constant_override("margin_bottom", 17)
	detail.add_child(detail_margin)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 9)
	detail_margin.add_child(details)
	details.add_child(_label("SELECTED SAMPLE", 12, MAP_INK_HEADER))
	_detail_name = _label("Select an item", 22, MAP_INK_DARK)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_detail_name)
	_detail_formula = _label("", 13, MAP_MUTED)
	details.add_child(_detail_formula)
	_detail_icon = LabItemIcon.new()
	_detail_icon.custom_minimum_size = Vector2(0, 112)
	_detail_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(_detail_icon)
	_detail_description = _label("", 14, MAP_MUTED)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(_detail_description)
	_detail_quantity = _label("", 13, MAP_INK_DARK)
	details.add_child(_detail_quantity)
	_equip_button = Button.new()
	_equip_button.custom_minimum_size = Vector2(0, 42)
	_equip_button.add_theme_font_size_override("font_size", 14)
	_apply_button_style(_equip_button, MAP_LEATHER, MAP_GOLD, MAP_CREAM)
	_equip_button.pressed.connect(_equip_or_return_selected)
	details.add_child(_equip_button)


func _build_footer(parent: Container) -> void:
	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 4)
	parent.add_child(divider)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	parent.add_child(footer)
	var slots_label := _label("QUICK SLOTS", 13, MAP_INK_HEADER)
	footer.add_child(slots_label)
	_hotbar = HBoxContainer.new()
	_hotbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	_hotbar.add_theme_constant_override("separation", 8)
	footer.add_child(_hotbar)
	var key_hint := _label("1–6 SELECT    •    CTRL + K SEARCH", 12, MAP_INK_HEADER)
	key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(key_hint)


func _refresh_all() -> void:
	_refresh_tabs()
	_refresh_grid()
	_refresh_detail()
	_refresh_hotbar()


func _refresh_tabs() -> void:
	for category in _tab_buttons:
		var tab: Button = _tab_buttons[category]
		if category == _active_category:
			_apply_button_style(tab, Color("7a3e19"), MAP_GOLD_BRIGHT, MAP_CREAM)
		else:
			_apply_button_style(tab, Color("c2a476"), MAP_LEATHER, MAP_INK_DARK)


func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
		
	if _storage_header != null:
		if _active_category == "Chemicals":
			_storage_header.text = "CHEMICAL STORAGE"
		elif _active_category == "Equipment":
			_storage_header.text = "EQUIPMENT STORAGE"
		elif _active_category == "Manuals":
			_storage_header.text = "MANUALS & GUIDES"

	if _active_category != "Chemicals":
		_empty_state.text = "🚧 COMING SOON 🚧\n%s features will be available in an upcoming update." % _active_category.to_upper()
		_empty_state.visible = true
		if _ai_status_label != null:
			_ai_status_label.visible = false
		return

	var search := _search.text.strip_edges().to_lower()
	var displayed := 0
	for item in _inventory.get_items():
		var category := str(item.get_property("category", ""))
		var haystack := "%s %s %s" % [item.get_title(), item.get_property("formula", ""), item.get_property("description", "")]
		if category != _active_category || (!search.is_empty() && !haystack.to_lower().contains(search)):
			continue
		_grid.add_child(_make_item_card(item))
		displayed += 1

	if displayed == 0:
		_empty_state.text = "No matching chemicals found."
		_empty_state.visible = true
	else:
		_empty_state.visible = false


func _on_search_text_changed(new_text: String) -> void:
	_refresh_grid()
	var term := new_text.strip_edges()
	if _active_category == "Chemicals" and term.length() >= 2:
		var found_local := false
		for item in _inventory.get_items():
			var haystack := "%s %s %s" % [item.get_title(), item.get_property("formula", ""), item.get_property("description", "")]
			if haystack.to_lower().contains(term.to_lower()):
				found_local = true
				break
				
		if not found_local:
			var sql_cache = get_node_or_null("/root/SQLCache")
			if sql_cache and sql_cache.has_method("get_chemical_info"):
				var cached_info = sql_cache.get_chemical_info(term)
				if cached_info != null:
					var item = _add_dynamic_chemical(cached_info)
					if item != null:
						_refresh_grid()
					return
					
			_search_timer.start(0.45)


func _on_search_timer_timeout() -> void:
	var term := _search.text.strip_edges()
	if term.length() >= 2 and _active_category == "Chemicals":
		var found_local := false
		for item in _inventory.get_items():
			var haystack := "%s %s %s" % [item.get_title(), item.get_property("formula", ""), item.get_property("description", "")]
			if haystack.to_lower().contains(term.to_lower()):
				found_local = true
				break
		if not found_local:
			_trigger_ai_chemical_lookup(term)


func _on_search_submitted(query: String) -> void:
	var search_term := query.strip_edges()
	if search_term.is_empty():
		return
	if _active_category != "Chemicals":
		_set_category("Chemicals")
	
	for item in _inventory.get_items():
		if item.get_title().to_lower() == search_term.to_lower() or str(item.get_property("formula", "")).to_lower() == search_term.to_lower():
			_select_item(item)
			_refresh_grid()
			return
			
	_trigger_ai_chemical_lookup(search_term)



func _trigger_ai_chemical_lookup(search_term: String) -> void:
	search_term = search_term.strip_edges()
	if search_term.is_empty() or _is_fetching_ai:
		return
		
	var sql_cache = get_node_or_null("/root/SQLCache")
	if sql_cache and sql_cache.has_method("get_chemical_info"):
		var cached_info = sql_cache.get_chemical_info(search_term)
		if cached_info != null:
			print("LabInventory: Found in SQLite cache -> ", search_term)
			var item = _add_dynamic_chemical(cached_info)
			if item != null:
				_set_category("Chemicals")
				_select_item(item)
				_search.text = item.get_title()
				_update_ai_status("Loaded '%s' from SQLite cache!" % item.get_title())
				_refresh_grid()
			return

	_is_fetching_ai = true
	_update_ai_status("Asking Groq AI for chemical details: '%s'..." % search_term)
	
	var prompt = """Act as a strict scientific chemistry database. Verify if "%s" is a REAL, scientifically recognized chemical compound, element, or valid IUPAC/common chemical name.

DO NOT HALLUCINATE OR INVENT FAKE CHEMICALS FOR SLANG, MISSPELLED WORDS, OR NON-CHEMICAL TERMS.

If "%s" is NOT a real recognized chemical compound or element, respond ONLY with:
{
  "name": "Not Available",
  "formula": "Not Available",
  "description": "The query does not correspond to a valid real chemical compound.",
  "color_name": "clear",
  "accent": "#8bf4ff"
}

If "%s" IS a real scientific chemical compound or element, respond ONLY with valid raw JSON:
{
  "name": "Full Scientific Name",
  "formula": "Chemical Formula",
  "description": "Short 1-2 sentence description.",
  "color_name": "One word liquid color: clear, red, blue, green, yellow, purple, orange, black, brown, white",
  "accent": "#hexcolor"
}""" % [search_term, search_term, search_term]

	var ai_service = get_node_or_null("/root/AIService")
	if ai_service:
		ai_service.request_ai(prompt, func(response_text: String, success: bool):
			_is_fetching_ai = false
			if success and not response_text.is_empty():
				var clean_text := response_text.strip_edges()
				if clean_text.begins_with("```json"):
					clean_text = clean_text.substr(7)
				if clean_text.begins_with("```"):
					clean_text = clean_text.substr(3)
				if clean_text.ends_with("```"):
					clean_text = clean_text.substr(0, clean_text.length() - 3)
				clean_text = clean_text.strip_edges()
				
				var parsed = JSON.parse_string(clean_text)
				if parsed is Dictionary and parsed.has("name"):
					var c_name := str(parsed.get("name", "")).strip_edges()
					var c_formula := str(parsed.get("formula", "")).strip_edges()
					var c_desc := str(parsed.get("description", "")).strip_edges()
					
					var n_low := c_name.to_lower()
					var f_low := c_formula.to_lower()
					var d_low := c_desc.to_lower()
					
					if n_low == "not available" or f_low == "not available" or n_low.contains("not available") or "does not correspond" in d_low or "not a valid" in d_low:
						_update_ai_status("❌ '%s' is not a valid chemical compound or element." % search_term)
						_refresh_grid()
						return

					if sql_cache and sql_cache.has_method("save_chemical_info"):
						sql_cache.save_chemical_info(search_term, parsed)
					
					var new_chem_item = _add_dynamic_chemical(parsed)
					if new_chem_item != null:
						_set_category("Chemicals")
						_select_item(new_chem_item)
						_update_ai_status("Generated '%s' via Groq AI & saved to SQLite!" % new_chem_item.get_title())
						_refresh_grid()
						return
			
			_update_ai_status("❌ Could not find a valid chemical matching '%s'." % search_term)
			_refresh_grid()
		)
	else:
		_is_fetching_ai = false
		_update_ai_status("AIService autoload not found.")


func _add_dynamic_chemical(chem_data: Dictionary) -> Variant:
	var chem_name: String = str(chem_data.get("name", "Unknown Chemical")).strip_edges()
	var chem_formula: String = str(chem_data.get("formula", "CHEM")).strip_edges()
	var chem_desc: String = str(chem_data.get("description", "")).strip_edges()
	
	var n_low := chem_name.to_lower()
	var f_low := chem_formula.to_lower()
	var d_low := chem_desc.to_lower()
	
	if n_low == "not available" or f_low == "not available" or n_low.contains("not available") or "does not correspond" in d_low:
		print("LabInventory: Refusing to create item for 'Not Available' -> ", chem_name)
		return null
	
	for existing in _inventory.get_items():
		var ex_name = existing.get_title().to_lower()
		var ex_formula = str(existing.get_property("formula", "")).to_lower()
		if ex_name == n_low or ex_formula == f_low:
			return existing

	var item = _inventory.create_and_add_item("naoh")
	if item != null:
		item.set_property("name", chem_name)
		item.set_property("formula", chem_formula)
		item.set_property("description", chem_desc)
		item.set_property("category", "Chemicals")
		item.set_property("kind", "chemical")
		item.set_property("accent", str(chem_data.get("accent", "#8bf4ff")))
		item.set_property("color_name", str(chem_data.get("color_name", "clear")))
	return item


func _load_cached_chemicals_from_db() -> void:
	var sql_cache = get_node_or_null("/root/SQLCache")
	if sql_cache and sql_cache.has_method("get_all_cached_chemicals"):
		var cached_list = sql_cache.get_all_cached_chemicals()
		for chem_data in cached_list:
			_add_dynamic_chemical(chem_data)


func _update_ai_status(msg: String) -> void:
	if _ai_status_label:
		_ai_status_label.text = msg



func _make_item_card(item) -> Button:
	var card := LabItemCard.new()
	card.item = item
	card.inventory_script = self
	card.custom_minimum_size = Vector2(132, 144)
	card.tooltip_text = "%s\n%s" % [item.get_title(), item.get_property("description", "")]
	var selected: bool = item == _selected_item
	_apply_button_style(card, Color("f5e5c9") if selected else Color("e6d3b3"), MAP_GOLD_BRIGHT if selected else MAP_LEATHER, MAP_INK_DARK)
	card.pressed.connect(_select_item.bind(item))
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 8
	content.offset_right = -10
	content.offset_bottom = -8
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 3)
	card.add_child(content)
	var icon := LabItemIcon.new()
	icon.custom_minimum_size = Vector2(0, 72)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_item_data(str(item.get_property("kind", "chemical")), _item_color(item))
	content.add_child(icon)
	var formula := _label(str(item.get_property("formula", item.get_title())), 15, MAP_INK_HEADER)
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(formula)
	var title_label := _label(item.get_title(), 11, MAP_MUTED)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_label)
	return card



func _refresh_detail() -> void:
	if _active_category != "Chemicals":
		_detail_name.text = _active_category.to_upper()
		_detail_formula.text = "COMING SOON"
		_detail_description.text = "The %s section is under active development. Interactive %s features will be unlocked in a future lab update!" % [_active_category.capitalize(), _active_category.to_lower()]
		_detail_quantity.text = ""
		_detail_icon.set_item_data("chemical", Color("4d5963"))
		_equip_button.disabled = true
		_equip_button.text = "COMING SOON"
		return

	if _selected_item == null:
		_detail_name.text = "Select an item"
		_detail_formula.text = ""
		_detail_description.text = "Choose a chemical reagent from your laboratory storage."
		_detail_quantity.text = ""
		_detail_icon.set_item_data("chemical", BLUE)
		_equip_button.disabled = true
		_equip_button.text = "EQUIP TO QUICK SLOT"
		return
	var item = _selected_item
	_detail_name.text = item.get_title()
	_detail_formula.text = "%s  •  %s" % [item.get_property("formula", "ITEM"), str(item.get_property("category", "")).to_upper()]
	_detail_description.text = str(item.get_property("description", ""))
	_detail_quantity.text = "QUANTITY   x%d" % item.get_stack_size()
	_detail_icon.set_item_data(str(item.get_property("kind", "chemical")), _item_color(item))
	var slot_index := _slot_index_for_item(item)
	_equip_button.disabled = false
	_equip_button.text = "RETURN TO INVENTORY" if slot_index >= 0 else "EQUIP TO SLOT %d" % (_target_slot_index() + 1)


func _refresh_hotbar() -> void:
	for child in _hotbar.get_children():
		child.queue_free()
	for child in _gameplay_hotbar.get_children():
		child.queue_free()
	for index in _quick_slots.size():
		var slot = _quick_slots[index]
		var item = slot.get_item()
		_hotbar.add_child(_make_slot_button(index, item, Vector2(92, 54)))
		_gameplay_hotbar.add_child(_make_slot_button(index, item, Vector2(92, 54)))


func _make_slot_button(index: int, item, dimensions: Vector2) -> Button:
	var button := LabSlotButton.new()
	button.slot_index = index
	button.item = item
	button.inventory_script = self
	button.custom_minimum_size = dimensions
	button.tooltip_text = "Slot %d" % (index + 1)
	button.add_theme_font_size_override("font_size", 16)
	if item != null:
		button.text = "%d   %s" % [index + 1, item.get_property("formula", item.get_title())]
		button.tooltip_text = "Slot %d: %s" % [index + 1, item.get_title()]
	else:
		button.text = "%d   —" % (index + 1)
		
	if index == _active_slot:
		_apply_button_style(button, Color("7a3e19"), MAP_GOLD_BRIGHT, MAP_CREAM)
	else:
		_apply_button_style(button, Color("3d2111d4"), Color("5c3316"), MAP_CREAM if item != null else MAP_PARCHMENT)
	button.pressed.connect(_select_slot.bind(index))
	return button


func _select_item(item) -> void:
	_selected_item = item
	var slot_index := _slot_index_for_item(item)
	if slot_index >= 0:
		_active_slot = slot_index
		_update_held_flask(item)
	_refresh_grid()
	_refresh_detail()
	_refresh_hotbar()


func _select_slot(index: int) -> void:
	if index < 0 or index >= _quick_slots.size():
		return
	_active_slot = index
	var item = _quick_slots[index].get_item()
	if item != null and _active_category == "Chemicals":
		_selected_item = item
	_refresh_hotbar()
	_refresh_detail()
	_update_held_flask(item)


func _set_category(category: String) -> void:
	_active_category = category
	if _active_category != "Chemicals":
		_selected_item = null
	_refresh_tabs()
	_refresh_grid()
	_refresh_detail()


func _equip_or_return_selected() -> void:
	if _selected_item == null:
		return
	var equipped_index := _slot_index_for_item(_selected_item)
	if equipped_index >= 0:
		_unequip_slot(equipped_index)
	else:
		_equip_item_to_slot(_selected_item, _target_slot_index())


func _equip_item_to_slot(item, target_slot_index: int) -> void:
	if item == null or target_slot_index < 0 or target_slot_index >= _quick_slots.size():
		return
	var current_slot_idx := _slot_index_for_item(item)
	var displaced_item = _quick_slots[target_slot_index].get_item()

	if current_slot_idx == target_slot_index:
		return

	if current_slot_idx >= 0:
		_quick_slots[current_slot_idx].clear()
		_quick_slots[target_slot_index].clear()
		if displaced_item != null and displaced_item != item:
			_quick_slots[current_slot_idx].equip(displaced_item)
		_quick_slots[target_slot_index].equip(item)
	else:
		if displaced_item != null:
			_quick_slots[target_slot_index].clear()
			_inventory.add_item(displaced_item)
		_quick_slots[target_slot_index].equip(item)

	_active_slot = target_slot_index
	_selected_item = item
	_refresh_all()
	_update_held_flask(_quick_slots[_active_slot].get_item())


func _swap_quick_slots(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= _quick_slots.size() or to_index < 0 or to_index >= _quick_slots.size():
		return
	if from_index == to_index:
		return
	var item_a = _quick_slots[from_index].get_item()
	var item_b = _quick_slots[to_index].get_item()
	_quick_slots[from_index].clear()
	_quick_slots[to_index].clear()
	if item_b != null:
		_quick_slots[from_index].equip(item_b)
	if item_a != null:
		_quick_slots[to_index].equip(item_a)
	_active_slot = to_index
	if item_a != null:
		_selected_item = item_a
	_refresh_all()
	_update_held_flask(_quick_slots[_active_slot].get_item())


func _unequip_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _quick_slots.size():
		return
	var item = _quick_slots[slot_index].get_item()
	if item == null:
		return
	_quick_slots[slot_index].clear()
	_inventory.add_item(item)
	if _active_slot == slot_index:
		_clear_held_flask()
	_selected_item = item
	_refresh_all()


func _create_drag_preview(item) -> Control:
	var preview := PanelContainer.new()
	preview.add_theme_stylebox_override("panel", _panel_style(Color("3b1d0ce6"), MAP_GOLD, 2, 8))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	preview.add_child(hbox)

	var icon := LabItemIcon.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_item_data(str(item.get_property("kind", "chemical")), _item_color(item))
	hbox.add_child(icon)

	var label := _label(str(item.get_property("formula", item.get_title())), 14, MAP_CREAM)
	hbox.add_child(label)

	return preview


func _target_slot_index() -> int:
	for index in _quick_slots.size():
		if _quick_slots[index].get_item() == null:
			return index
	return _active_slot


func _slot_index_for_item(item) -> int:
	for index in _quick_slots.size():
		if _quick_slots[index].get_item() == item:
			return index
	return -1


func _item_color(item) -> Color:
	return Color.from_string(str(item.get_property("accent", "#8bf4ff")), CYAN)


func _open_inventory() -> void:
	if _ui.visible:
		return
	_restore_player_input()
	_refresh_all()
	_ui.show()
	_gameplay_hotbar.get_parent().hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _close_inventory() -> void:
	if !_ui.visible:
		return
	_ui.hide()
	_gameplay_hotbar.get_parent().show()
	_search.release_focus()
	if _player_controller != null:
		_player_controller.can_move = _restore_can_move
		_player_controller.set_process_unhandled_input(_restore_unhandled_input)
		_player_controller.capture_mouse()


func _on_player_object_dropped(obj) -> void:
	if _held_flask != null:
		var current_body = _held_flask if _held_flask is RigidBody3D else _held_flask.get_node_or_null("RigidBody3D")
		if current_body == obj or _held_flask == obj:
			_held_flask = null


func _on_player_object_picked(obj) -> void:
	if obj != null:
		if obj.name.begins_with("HeldChemicalFlask") or (obj.get_parent() != null and obj.get_parent().name.begins_with("HeldChemicalFlask")):
			var flask_node = obj
			if not (obj is RigidBody3D) and obj.get_parent() != null:
				flask_node = obj.get_parent()
			elif obj.get_parent() != null and obj.get_parent().name.begins_with("HeldChemicalFlask"):
				flask_node = obj.get_parent()
			_held_flask = flask_node


func _update_held_flask(item) -> void:
	if item == null || str(item.get_property("category", "")) != "Chemicals":
		_clear_held_flask()
		return
	var chemical_name := str(item.get_property("formula", item.get_title()))
	if is_instance_valid(_held_flask):
		var current_body = _held_flask if _held_flask is RigidBody3D else _held_flask.get_node_or_null("RigidBody3D")
		if is_instance_valid(current_body) and "chemical_name" in current_body and current_body.chemical_name == chemical_name:
			return
	_clear_held_flask()
	if _player_controller == null:
		_player_controller = get_parent().get_node_or_null("ProtoController")
	if _player_controller != null:
		if _player_controller.has_signal("object_dropped") and not _player_controller.object_dropped.is_connected(_on_player_object_dropped):
			_player_controller.object_dropped.connect(_on_player_object_dropped)
		if _player_controller.has_signal("object_picked") and not _player_controller.object_picked.is_connected(_on_player_object_picked):
			_player_controller.object_picked.connect(_on_player_object_picked)
	if _player_controller == null:
		return

	if is_instance_valid(_player_controller.picked_object):
		var picked = _player_controller.picked_object
		if picked.name.begins_with("HeldChemicalFlask") or (picked.get_parent() != null and picked.get_parent().name.begins_with("HeldChemicalFlask")):
			_player_controller.remove_object()
		
	var world_scene = get_tree().current_scene
	if world_scene == null:
		return
		
	var flask_instance = FlaskScene.instantiate()
	flask_instance.name = "HeldChemicalFlask"
	
	var flask_body: RigidBody3D = null
	if flask_instance is RigidBody3D:
		flask_body = flask_instance
	else:
		flask_body = flask_instance.get_node_or_null("RigidBody3D")
		
	if flask_body != null:
		flask_body.chemical_name = chemical_name
		flask_body.freeze = false
		flask_body.collision_layer = 1
		flask_body.collision_mask = 1
		flask_body.set_physics_process(true)
		
	_held_flask = flask_instance
	flask_instance.tree_exited.connect(func():
		if _held_flask == flask_instance:
			_held_flask = null
	, CONNECT_ONE_SHOT)

	flask_instance.tree_entered.connect(func():
		if is_instance_valid(flask_body) and is_instance_valid(_player_controller) and _player_controller.has_method("pick_target_object"):
			if _held_flask == flask_instance:
				_player_controller.call_deferred("pick_target_object", flask_body)
	, CONNECT_ONE_SHOT)
	
	world_scene.add_child.call_deferred(flask_instance)



func _clear_held_flask() -> void:
	if not is_instance_valid(_held_flask) and _player_controller != null and is_instance_valid(_player_controller.picked_object):
		var picked = _player_controller.picked_object
		if picked.name.begins_with("HeldChemicalFlask") or (picked.get_parent() != null and picked.get_parent().name.begins_with("HeldChemicalFlask")):
			_held_flask = picked.get_parent() if (picked.get_parent() != null and picked.get_parent().name.begins_with("HeldChemicalFlask")) else picked

	if not is_instance_valid(_held_flask):
		_held_flask = null
		if _player_controller != null and is_instance_valid(_player_controller.picked_object):
			var picked = _player_controller.picked_object
			if picked.name.begins_with("HeldChemicalFlask") or (picked.get_parent() != null and picked.get_parent().name.begins_with("HeldChemicalFlask")):
				_player_controller.remove_object()
		return

	var flask_to_free = _held_flask
	_held_flask = null
	if _player_controller != null:
		var current_body = flask_to_free if flask_to_free is RigidBody3D else flask_to_free.get_node_or_null("RigidBody3D")
		if current_body != null and _player_controller.picked_object == current_body:
			_player_controller.remove_object()
		elif _player_controller.picked_object == flask_to_free:
			_player_controller.remove_object()

	if is_instance_valid(flask_to_free) and flask_to_free.is_inside_tree() and (flask_to_free.name.begins_with("HeldChemicalFlask") or (flask_to_free.get_parent() != null and flask_to_free.get_parent().name.begins_with("HeldChemicalFlask"))):
		flask_to_free.queue_free()





func _restore_player_input() -> void:
	if _player_controller == null:
		return
	_restore_can_move = _player_controller.can_move
	_restore_unhandled_input = _player_controller.is_processing_unhandled_input()
	_player_controller.can_move = false
	_player_controller.set_process_unhandled_input(false)
	_player_controller.release_mouse()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if !_ui.visible:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var prev_slot := (_active_slot - 1 + _quick_slots.size()) % _quick_slots.size()
				_select_slot(prev_slot)
				get_viewport().set_input_as_handled()
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var next_slot := (_active_slot + 1) % _quick_slots.size()
				_select_slot(next_slot)
				get_viewport().set_input_as_handled()
				return

	if !(event is InputEventKey) || !event.pressed || event.echo:
		return
	if event.ctrl_pressed && event.keycode == KEY_K:
		_open_inventory()
		_search.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_I && !(_ui.visible && _search.has_focus()):
		if _ui.visible:
			_close_inventory()
		else:
			_open_inventory()
		get_viewport().set_input_as_handled()
		return
	if _ui.visible && event.keycode == KEY_ESCAPE:
		_close_inventory()
		get_viewport().set_input_as_handled()
		return
	if !(_ui.visible && _search.has_focus()) && !event.ctrl_pressed && !event.alt_pressed && !event.meta_pressed:
		var hotkey: int = int(event.keycode) - int(KEY_1)
		if hotkey >= 0 && hotkey < _quick_slots.size():
			_select_slot(hotkey)
			get_viewport().set_input_as_handled()


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _apply_button_style(button: Button, fill: Color, border: Color, font_color: Color) -> void:
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", MAP_CREAM if font_color == MAP_CREAM else MAP_INK_DARK)
	button.add_theme_color_override("font_pressed_color", MAP_GOLD_BRIGHT)
	button.add_theme_stylebox_override("normal", _panel_style(fill, border, 1, 10))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.08), border.lightened(0.12), 1, 10))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.1), border, 1, 10))
	button.add_theme_stylebox_override("disabled", _panel_style(fill.darkened(0.3), Color("5c3316"), 1, 10))


func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
