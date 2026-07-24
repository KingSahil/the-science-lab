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
4. **Mandatory Console Error & Headless Verification**:
   - ALWAYS verify GDScript syntax, C++ console errors, resource loading, and texture `.import` validity before completing tasks:
     ```powershell
     & "C:\Users\sahil\OneDrive\Desktop\Godot_v4.7.1.exe" --path . --headless --check-only
     powershell -ExecutionPolicy Bypass -File .agents/skills/groq-godot-ai/scripts/check_errors.ps1
     ```

5. **Mandatory Source Control Check Before Git Messages**:
   - BEFORE drafting or providing any Git commit message, ALWAYS check current source control status (`git status` and `git diff --stat`) to ensure commit messages accurately reflect modified and untracked files:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .agents/skills/git-status-commit/scripts/check_git_status.ps1
     ```

## Available Skills
- `groq-godot-ai`: Groq API with Gemma Ollama fallback, `.env` parsing, documentation check workflow, SQLite chemistry caching, and console error verification script.
- `git-status-commit`: Inspects current Git source control working tree condition (`git status` & `git diff`) before providing Git commit messages.
