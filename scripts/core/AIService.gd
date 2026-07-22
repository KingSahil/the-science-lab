extends Node


# --- Groq API Settings ---
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
const GROQ_MODEL = "llama-3.3-70b-versatile"

# --- Gemma / Ollama Fallback Settings ---
const OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
const GEMMA_MODEL = "gemma4:4b"

# Optional API Key override (if empty, checks OS.get_environment("GROQ_API_KEY") or .env file)
@export var groq_api_key: String = ""

func _ready() -> void:
	_load_env_file()

func _load_env_file() -> void:
	var paths = ["res://.env", "./.env"]
	for path in paths:
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				while not file.eof_reached():
					var line = file.get_line().strip_edges()
					if line == "" or line.begins_with("#"):
						continue
					if "=" in line:
						var parts = line.split("=", true, 1)
						var key = parts[0].strip_edges()
						var val = parts[1].strip_edges()
						if (val.begins_with('"') and val.ends_with('"')) or (val.begins_with("'") and val.ends_with("'")):
							val = val.substr(1, val.length() - 2)
						if key == "GROQ_API_KEY" and val != "":
							groq_api_key = val
							print("AIService: Loaded GROQ_API_KEY from .env file!")

func request_ai(prompt: String, callback: Callable, temperature: float = 0.1, max_tokens: int = 0) -> void:
	var key = groq_api_key
	if key == "":
		key = OS.get_environment("GROQ_API_KEY")

	if key != "":
		print("AIService: GROQ_API_KEY found. Attempting Groq API request...")
		_send_groq_request(prompt, key, callback, temperature, max_tokens)
	else:
		print("AIService: GROQ_API_KEY not set. Falling back to Gemma (Ollama)...")
		_send_gemma_request(prompt, callback, temperature, max_tokens)


func _send_groq_request(prompt: String, api_key: String, callback: Callable, temperature: float, max_tokens: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json and json is Dictionary and json.has("choices") and json["choices"].size() > 0:
				var choice = json["choices"][0]
				if choice.has("message") and choice["message"].has("content"):
					var text_out: String = choice["message"]["content"]
					print("AIService: Groq response received successfully!")
					callback.call(text_out, true)
					http.queue_free()
					return
		
		print("AIService: Groq API failed (HTTP ", response_code, "). Falling back to Gemma (Ollama)...")
		http.queue_free()
		_send_gemma_request(prompt, callback, temperature, max_tokens)
	)
	
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	])
	
	var payload: Dictionary = {
		"model": GROQ_MODEL,
		"messages": [
			{"role": "user", "content": prompt}
		],
		"temperature": temperature
	}
	if max_tokens > 0:
		payload["max_tokens"] = max_tokens
		
	var err = http.request(GROQ_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		print("AIService: Failed to initiate HTTP request to Groq. Error: ", err, ". Falling back to Gemma...")
		http.queue_free()
		_send_gemma_request(prompt, callback, temperature, max_tokens)

func _send_gemma_request(prompt: String, callback: Callable, temperature: float, max_tokens: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json and json is Dictionary and json.has("response"):
				var text_out: String = json["response"]
				print("AIService: Gemma response received successfully!")
				callback.call(text_out, true)
				http.queue_free()
				return
		
		print("AIService: Gemma (Ollama) request failed with HTTP status ", response_code)
		callback.call("", false)
		http.queue_free()
	)
	
	var headers = PackedStringArray(["Content-Type: application/json"])
	var body_data: Dictionary = {
		"model": GEMMA_MODEL,
		"prompt": prompt,
		"stream": false,
		"temperature": temperature
	}
	if max_tokens > 0:
		body_data["options"] = {"num_predict": max_tokens, "temperature": temperature}
		
	var err = http.request(OLLAMA_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body_data))
	if err != OK:
		print("AIService: Failed to initiate HTTP request to Ollama. Error: ", err)
		callback.call("", false)
		http.queue_free()
