---
name: groq-godot-ai
description: Manages Groq API integration with Gemma (Ollama) fallback, .env parsing, documentation checks, and SQLite chemistry caching in Godot 4.
---

# Groq API + Gemma Fallback Skill for Godot 4

This skill provides guidelines and patterns for implementing AI-driven features in Godot 4 using Groq API as primary model and Gemma (via Ollama) as local fallback.

## Mandatory Workflow Rules

1. **Check Latest Documentation First**:
   - Before proposing solutions or writing GDScript/API code, always search and consult official documentation:
     - **Godot 4 Engine Documentation**: [https://docs.godotengine.org/en/stable/](https://docs.godotengine.org/en/stable/)
     - **Groq API Documentation**: [https://console.groq.com/docs/](https://console.groq.com/docs/)

2. **Mandatory Headless Testing**:
   - Always run the headless check before completing a task:
     ```powershell
     & "C:\Users\sahil\OneDrive\Desktop\Godot_v4.7.1.exe" --path . --headless --check-only
     ```

## Key Features

1. **Groq API Integration**:
   - Model: `llama-3.3-70b-versatile`
   - Endpoint: `https://api.groq.com/openai/v1/chat/completions`
   - Authorization: `Bearer <GROQ_API_KEY>`

2. **Automatic Fallback to Gemma (Ollama)**:
   - Model: `gemma3:4b`
   - Endpoint: `http://127.0.0.1:11434/api/generate`
   - Triggered when `GROQ_API_KEY` is missing or when Groq API request fails/times out.

3. **Automatic `.env` Parsing**:
   - Reads `.env` from `res://.env` or `./.env` on `_ready()`.
   - Parses key-value pairs (e.g. `GROQ_API_KEY=gsk_...`).

4. **SQLite Cache**:
   - Checks `SQLCache` autoload node before querying AI endpoints.
   - Saves chemical colors and reaction outputs to avoid redundant API calls.

## Architecture

- **`scripts/core/AIService.gd`**: Autoload singleton node (`/root/AIService`).
- **`scripts/flasks/flask.gd`**: Queries `AIService` for liquid colors.
- **`scripts/core/ReactionLabel.gd`**: Queries `AIService` for reaction predictions and explanations.

## Quickstart

1. Place your API key in `.env`:
   ```ini
   GROQ_API_KEY=gsk_your_groq_api_key_here
   ```
2. Call `AIService`:
   ```gdscript
   var ai_node = get_node_or_null("/root/AIService")
   if ai_node:
       ai_node.request_ai(prompt, func(response_text: String, success: bool):
           if success:
               print("AI Response: ", response_text)
       )
   ```
