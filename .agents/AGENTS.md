# Antigravity Workspace Guidelines for The Science Lab

## Workspace Overview
This repository ("The Science Lab") is a Godot 4 3D project simulating chemical liquids, flask interactions, and AI-driven reaction explanations.

## Mandatory Rules & Guidelines
1. **Always Check Latest Documentation First**:
   - BEFORE writing code, debugging, or proposing solutions, ALWAYS consult the latest official documentation:
     - Godot 4 Engine Docs: [https://docs.godotengine.org/en/stable/](https://docs.godotengine.org/en/stable/)
     - Groq API Docs: [https://console.groq.com/docs/](https://console.groq.com/docs/)
2. **Autoload vs Class Name**:
   - In Godot 4, avoid adding `class_name` to scripts registered as Autoload singletons in `project.godot` to prevent `Class hides autoload singleton` parser errors.
3. **Environment Variables**:
   - Use `AIService` automatic `.env` reader or `OS.get_environment("GROQ_API_KEY")`.
4. **Mandatory Headless Verification**:
   - ALWAYS verify GDScript syntax & engine execution before completing tasks:
     ```powershell
     & "C:\Users\sahil\OneDrive\Desktop\Godot_v4.7.1.exe" --path . --headless --check-only
     ```

## Available Skills
- `groq-godot-ai`: Groq API with Gemma Ollama fallback, `.env` parsing, documentation check workflow, and SQLite reaction caching.
