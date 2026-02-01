extends RigidBody3D

@onready var particles = $GPUParticles3D
@onready var liquid_mesh = $lab_erlenmeyer_a_0/liquid_mesh 
@onready var pour_ray: RayCast3D = $RayCast3D
# Safe fetch for optional nodes
@onready var reaction_particles: GPUParticles3D = get_node_or_null("ReactionParticles")

@export var chemical_name: String = "Water" 
@export var current_liquid_height: float = 0.25
@export var max_liquid_height: float = 1.0 

# --- CONFIGURATION ---
const OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
const MODEL_NAME = "gemma3:4b" 

const COLOR_MAP = {
	"clear": Color(0.8, 0.9, 1.0, 0.3),
	"white": Color.WHITE,
	"red": Color.RED,
	"pink": Color.HOT_PINK,
	"blue": Color(0.0, 0.0, 1.0, 0.8),
	"green": Color.GREEN,
	"yellow": Color.YELLOW,
	"purple": Color.PURPLE,
	"orange": Color.ORANGE,
	"black": Color.BLACK,
	"brown": Color.SADDLE_BROWN
}

const TILT_THRESHOLD = 90
const DRAIN_SPEED = 0.2
const FILL_SPEED = 0.2
var last_reaction_time = 0.0

func _ready():
	update_visuals()
	
	if chemical_name != "" and chemical_name != "Water":
		fetch_initial_color()
	else:
		apply_color_by_name("clear")

# --- AUTO-COLOR LOGIC (UPDATED WITH CACHE) ---
func fetch_initial_color():
	# 1. TRY CACHE FIRST
	if has_node("/root/SQLCache"):
		var cached_color = get_node("/root/SQLCache").get_chemical_color(chemical_name)
		if cached_color:
			print(name, ": Cache Hit! Loaded color for ", chemical_name)
			apply_color_by_name(cached_color)
			return # Stop here, don't ask Gemma
			
	# 2. CACHE MISS? ASK GEMMA
	print(name, ": Cache Miss. Asking Gemma for color of ", chemical_name)
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_color_received.bind(http))
	
	var prompt = "What is the visual color of liquid " + chemical_name + "? Return ONLY one word (e.g., Blue, Clear, Red)."
	var body_data = { "model": MODEL_NAME, "prompt": prompt, "stream": false }
	
	http.request(OLLAMA_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body_data))

func _on_color_received(_result, response_code, _headers, body, http_node):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and "response" in json:
			var color_name = json["response"].strip_edges().to_lower()
			color_name = color_name.replace(".", "")
			
			print(name, ": Gemma says color is ", color_name)
			apply_color_by_name(color_name)
			
			# 3. SAVE TO CACHE
			if has_node("/root/SQLCache"):
				get_node("/root/SQLCache").save_chemical_color(chemical_name, color_name)
	
	http_node.queue_free()

func apply_color_by_name(color_name: String):
	var target_color = Color(0.8, 0.9, 1.0, 0.5) 
	
	for key in COLOR_MAP:
		if key in color_name:
			target_color = COLOR_MAP[key]
			break
			
	if liquid_mesh:
		var mat = liquid_mesh.material_override
		if not mat: mat = liquid_mesh.get_active_material(0)
		
		if mat:
			if not mat.resource_local_to_scene:
				mat.resource_local_to_scene = true
				
			# Fix shader parameter naming (using the one from your screenshot)
			mat.set_shader_parameter("Liquid Surface Color", target_color)
			# Fallbacks
			mat.set_shader_parameter("color", target_color)
			mat.set_shader_parameter("albedo", target_color)
			mat.set_shader_parameter("liquid_surface_color", target_color)

# --- PHYSICS LOGIC ---
func _physics_process(delta):
	var rot = rotation_degrees
	if abs(rot.x) > TILT_THRESHOLD or abs(rot.z) > TILT_THRESHOLD:
		if current_liquid_height > -0.6:
			particles.emitting = true
			current_liquid_height -= DRAIN_SPEED * delta
			update_visuals()
			handle_pouring(delta)
		else:
			particles.emitting = false
	else:
		particles.emitting = false

func handle_pouring(delta):
	if not pour_ray: return
	pour_ray.global_rotation = Vector3.ZERO
	pour_ray.force_raycast_update()
	if pour_ray.is_colliding():
		var hit_object = pour_ray.get_collider()
		if hit_object.has_method("fill_liquid"):
			hit_object.fill_liquid(FILL_SPEED * delta, chemical_name)

func fill_liquid(amount, incoming_chem_type = ""):
	if current_liquid_height < max_liquid_height:
		current_liquid_height += amount
		update_visuals()
		if incoming_chem_type != "" and incoming_chem_type != chemical_name:
			trigger_reaction_text(incoming_chem_type)

func trigger_reaction_text(incoming_chem):
	var current_time = Time.get_ticks_msec()
	if current_time - last_reaction_time < 5000: return
	last_reaction_time = current_time
	
	var full_message = incoming_chem + " + " + chemical_name
	get_tree().call_group("ReactionHUD", "show_reaction", full_message, self)

func apply_reaction_effects(new_color_name: String, effect_type: String):
	apply_color_by_name(new_color_name)
	
	if reaction_particles:
		reaction_particles.emitting = true
		var material = reaction_particles.process_material as ParticleProcessMaterial
		if material:
			effect_type = effect_type.to_lower()
			if "smoke" in effect_type: material.gravity = Vector3(0, 1, 0)
			elif "precipitate" in effect_type: material.gravity = Vector3(0, -1, 0)
			else: material.gravity = Vector3(0, 0.5, 0)

func update_visuals():
	if liquid_mesh and liquid_mesh.has_method("update_liquid_height"):
		liquid_mesh.update_liquid_height(current_liquid_height)
