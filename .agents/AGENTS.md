# Antigravity Workspace Guidelines for The Science Lab

## Workspace Overview
This repository ("The Science Lab") is a Godot 4 3D project simulating chemical liquids, flask interactions, and AI-driven reaction explanations.

## Agent Behavior & Rules
- **Autoload vs Class Name**: In Godot 4, avoid adding `class_name` to scripts registered as Autoload singletons in `project.godot` to prevent `Class hides autoload singleton` parser errors.
- **Environment Variables**: Use `AIService` automatic `.env` reader or `OS.get_environment("GROQ_API_KEY")`.
- **Headless Testing**: Execute Godot headless testing using:
  ```powershell
  & "C:\Users\sahil\OneDrive\Desktop\Godot_v4.7.1.exe" --path . --headless --check-only
  ```

## Available Skills
- `groq-godot-ai`: Groq API with Gemma Ollama fallback and SQLite reaction caching.
