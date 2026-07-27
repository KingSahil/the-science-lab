extends Node

var db = null
const DB_NAME = "user://chemistry_cache.db"

func _ready():
	if not ClassDB.class_exists("SQLite"):
		printerr("ERROR: Godot-SQLite plugin is not installed!")
		return
		
	db = SQLite.new()
	db.path = DB_NAME
	db.open_db()
	
	# 1. Table for REACTIONS (Pairs)
	var reaction_table = {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true},
		"chemicals_key": {"data_type": "text", "not_null": true},
		"product": {"data_type": "text"},
		"color": {"data_type": "text"},
		"effect": {"data_type": "text"},
		"explanation": {"data_type": "text"}
	}
	db.create_table("reactions", reaction_table)
	
	# 2. NEW Table for SINGLE COLORS (e.g. "Uranium" -> "Green")
	var color_table = {
		"name": {"data_type": "text", "primary_key": true},
		"color_name": {"data_type": "text"}
	}
	db.create_table("chemical_colors", color_table)

	# 3. Table for UNLIMITED CHEMICAL CACHE
	var chem_info_table = {
		"chem_key": {"data_type": "text", "primary_key": true},
		"name": {"data_type": "text"},
		"formula": {"data_type": "text"},
		"category": {"data_type": "text"},
		"description": {"data_type": "text"},
		"kind": {"data_type": "text"},
		"accent": {"data_type": "text"},
		"color_name": {"data_type": "text"}
	}
	db.create_table("chemical_info", chem_info_table)
	clear_stale_explanations()
	remove_invalid_cached_chemicals()

# --- REACTION LOGIC ---
func save_reaction(chem_a, chem_b, product, color, effect, explanation=""):
	if not db: return
	var ingredients = [chem_a, chem_b]
	ingredients.sort()
	var key = ingredients[0] + "+" + ingredients[1]
	
	var data = {
		"chemicals_key": key, "product": product, 
		"color": color, "effect": effect, "explanation": explanation
	}
	db.insert_row("reactions", data)

func get_cached_reaction(chem_a, chem_b):
	if not db: return null
	var ingredients = [chem_a, chem_b]
	ingredients.sort()
	var key = ingredients[0] + "+" + ingredients[1]
	
	db.query("SELECT * FROM reactions WHERE chemicals_key = '" + key + "'")
	if db.query_result.size() > 0:
		return db.query_result[0]
	return null

func update_reaction_explanation(chem_a: String, chem_b: String, explanation: String) -> void:
	if not db: return
	var ingredients = [chem_a, chem_b]
	ingredients.sort()
	var key = ingredients[0] + "+" + ingredients[1]
	
	db.query("UPDATE reactions SET explanation = '" + explanation.replace("'", "''") + "' WHERE chemicals_key = '" + key + "'")
	print("SQLCache: Updated explanation in SQLite for ", key)

func clear_stale_explanations() -> void:
	if not db: return
	db.query("UPDATE reactions SET explanation = '' WHERE explanation NOT LIKE '%VISUAL%' AND explanation NOT LIKE '%DIAGRAM%'")
	print("SQLCache: Cleared stale reaction explanations.")

func remove_invalid_cached_chemicals() -> void:
	if not db: return
	db.query("DELETE FROM chemical_info WHERE LOWER(name) LIKE '%not available%' OR LOWER(formula) LIKE '%not available%' OR LOWER(chem_key) LIKE '%not available%' OR LOWER(description) LIKE '%does not correspond%' OR LOWER(name) LIKE '%niggi%' OR LOWER(chem_key) LIKE '%niggi%' OR LOWER(chem_key) LIKE '%nigg%'")
	print("SQLCache: Purged invalid 'Not Available' and hallucinatory records from SQLite chemical cache.")


# --- COLOR LOGIC ---
func save_chemical_color(chem_name, color_name):
	if not db: return
	# Create dictionary for insert
	var data = {"name": chem_name, "color_name": color_name}
	# Insert (or replace if exists)
	db.insert_row("chemical_colors", data)
	print("Saved Color to Cache: ", chem_name, " -> ", color_name)

func get_chemical_color(chem_name):
	if not db: return null
	db.query("SELECT color_name FROM chemical_colors WHERE name = '" + chem_name.replace("'", "''") + "'")
	if db.query_result.size() > 0:
		return db.query_result[0]["color_name"]
	return null

# --- DYNAMIC CHEMICAL DEFINITIONS CACHE ---
func save_chemical_info(chem_key: String, chem_data: Dictionary) -> void:
	if not db: return
	var clean_key = chem_key.strip_edges().to_lower()
	var name_val := str(chem_data.get("name", chem_key.capitalize())).strip_edges()
	var formula_val := str(chem_data.get("formula", chem_key.to_upper())).strip_edges()
	var desc_val := str(chem_data.get("description", "A chemical compound.")).strip_edges()
	
	if name_val.to_lower() == "not available" or formula_val.to_lower() == "not available" or name_val.to_lower().contains("not available") or "does not correspond to a known chemical" in desc_val.to_lower():
		print("SQLCache: Blocked saving 'Not Available' to SQLite for ", clean_key)
		return

	var data = {
		"chem_key": clean_key,
		"name": name_val,
		"formula": formula_val,
		"category": "Chemicals",
		"description": desc_val,
		"kind": "chemical",
		"accent": str(chem_data.get("accent", "#8bf4ff")),
		"color_name": str(chem_data.get("color_name", "clear"))
	}
	db.insert_row("chemical_info", data)
	save_chemical_color(data["name"], data["color_name"])
	save_chemical_color(data["formula"], data["color_name"])
	save_chemical_color(clean_key, data["color_name"])
	print("SQLCache: Saved Chemical Info to SQLite -> ", data["name"], " (", data["formula"], ")")

func get_chemical_info(search_term: String) -> Variant:
	if not db: return null
	var term = search_term.strip_edges().to_lower().replace("'", "''")
	if term.is_empty(): return null
	db.query("SELECT * FROM chemical_info WHERE chem_key = '" + term + "' OR LOWER(name) = '" + term + "' OR LOWER(formula) = '" + term + "'")
	if db.query_result.size() > 0:
		return db.query_result[0]
	return null

func get_all_cached_chemicals() -> Array:
	if not db: return []
	db.query("SELECT * FROM chemical_info")
	return db.query_result

