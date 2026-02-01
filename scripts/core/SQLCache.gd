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

# --- NEW: COLOR LOGIC ---
func save_chemical_color(chem_name, color_name):
	if not db: return
	# Create dictionary for insert
	var data = {"name": chem_name, "color_name": color_name}
	# Insert (or replace if exists)
	db.insert_row("chemical_colors", data)
	print("Saved Color to Cache: ", chem_name, " -> ", color_name)

func get_chemical_color(chem_name):
	if not db: return null
	db.query("SELECT color_name FROM chemical_colors WHERE name = '" + chem_name + "'")
	if db.query_result.size() > 0:
		return db.query_result[0]["color_name"]
	return null
