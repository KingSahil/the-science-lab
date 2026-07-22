# Antigravity Documentation - The Science Lab

## Overview
This project uses **Antigravity AI Agent** for pair-programming, automated testing, and LLM integrations.

## Core Rules & Workflow
1. **Mandatory Documentation Inspection**:
   - Before coding or proposing solutions, Antigravity consults the latest official documentation:
     - [Godot 4 Stable Documentation](https://docs.godotengine.org/en/stable/)
     - [Groq API Quickstart & Reference Docs](https://console.groq.com/docs/)

2. **Automated Headless Verification**:
   - Every code change is verified headlessly using the local Godot binary:
     ```powershell
     & "C:\Users\sahil\OneDrive\Desktop\Godot_v4.7.1.exe" --path . --headless --check-only
     ```

## Groq API & Gemma Fallback System

### Architecture
```
+-------------------+        +--------------------+
|  flask.gd /       |        |   SQLCache         |
|  ReactionLabel.gd |-----> | (Local SQLite DB)  |
+-------------------+        +--------------------+
          |                            | (Miss)
          v                            v
+-------------------------------------------------+
|                  AIService                      |
|  1. Parses .env for GROQ_API_KEY               |
|  2. Tries Groq API (llama-3.3-70b-versatile)     |
|  3. Falls back to Gemma 3:4b (Ollama local)     |
+-------------------------------------------------+
```

### Configuration (`.env`)
Create a `.env` file in the project root:
```ini
GROQ_API_KEY=gsk_your_groq_api_key_here
OLLAMA_URL=http://127.0.0.1:11434/api/generate
GEMMA_MODEL=gemma3:4b
```
