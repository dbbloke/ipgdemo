# 3D Adventure Game Demo

This repository contains a small but featureful 3D adventure game using the [Ursina](https://www.ursinaengine.org/) engine. The code is split into multiple modules inside the `game` package to make it easier to extend.

## Requirements

- Python 3.8+
- `ursina` Python package (`pip install ursina`)

## Running the Game

```bash
python adventure_game.py
```

### Controls

- WASD to move around on foot.
- Press `E` to interact with characters.
- Collect three coins for Bob, then deliver them to Alice.
- Stand near the plane and press `P` to start flying.
- While flying, use WASD to move horizontally, `Space` to ascend, `Shift` to descend, and press `Q` to exit the plane.

### Features

- Inventory system for collecting items such as coins.
- Multi-stage quest line involving Bob and Alice.
- Decorative city buildings and randomly placed trees.
- Simple heads-up display showing collected coins.
- Flyable plane with vertical controls.

## File Overview

- `adventure_game.py` – main entry point that assembles the game.
- `game/environment.py` – spawns the ground, city buildings, and trees.
- `game/npc.py` – contains the `NPC` entity class.
- `game/plane.py` – helper for creating the plane entity.
- `game/quests.py` – quest manager used for NPC interactions.
- `game/controls.py` – handles plane flight controls.
- `game/player.py` – player controller with an inventory.
- `game/items.py` – collectable items such as coins.
- `game/hud.py` – simple HUD for displaying player stats.

Feel free to explore these modules if you want to expand the demo with more mechanics or content.
