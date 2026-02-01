# The Science Lab

A 3D chemistry laboratory simulation built with Godot Engine featuring interactive flasks, liquid physics, and chemical reactions.

## Project Structure

```
the-science-lab/
├── scenes/           # All scene files (.tscn)
│   ├── main/        # Main game scenes
│   ├── flasks/      # Flask-related scenes
│   ├── liquids/     # Liquid effect scenes
│   └── demos/       # Demo/test scenes
│
├── scripts/         # All GDScript files (.gd)
│   ├── core/        # Core systems (ChemistryDB, SQLCache, ReactionLabel)
│   ├── flasks/      # Flask behavior scripts
│   └── liquids/     # Liquid simulation scripts
│
├── shaders/         # Shader files (.gdshader)
│   ├── liquid_shader.gdshader     # Main liquid shader
│   └── liquid_alt.gdshader        # Alternative liquid shader
│
├── models/          # 3D models and materials
│   ├── flasks/      # Flask GLB files
│   ├── materials/   # Material files
│   └── *.glb        # Other 3D models
│
├── textures/        # Texture and image files
├── data/            # Data files (CSV, translations)
├── addons/          # Third-party addons and plugins
└── archive/         # Deprecated/old implementations
```

## Features

- Interactive 3D flasks with realistic liquid physics
- Chemical reaction system with color changes
- Shader-based liquid rendering with wobble effects
- SQL-based caching for chemical data
- First-person character controller
- Chemistry database for reactions

## Getting Started

1. Open the project in Godot Engine 4.x
2. Run the main scene: `scenes/main/node_3d.tscn`
3. Use WASD to move and mouse to interact with flasks

