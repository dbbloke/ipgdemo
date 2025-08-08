from ursina import Entity, color
import random


def create_ground():
    """Create the base ground plane."""
    return Entity(model='plane', collider='box', scale=64, color=color.gray)


def create_city():
    """Spawn a few simple buildings to form a city."""
    buildings = []
    for x in range(-5, 6, 2):
        for z in range(-5, 6, 2):
            if abs(x) + abs(z) > 2:
                b = Entity(
                    model='cube',
                    scale=(1, random.uniform(1, 3), 1),
                    position=(x, 0.5, z),
                    color=color.dark_gray,
                    collider='box',
                )
                buildings.append(b)
    return buildings


def create_trees(amount=6):
    """Spawn some simple trees for decoration."""
    trees = []
    for _ in range(amount):
        x = random.uniform(-6, 6)
        z = random.uniform(-6, 6)
        trunk = Entity(
            model='cube',
            scale=(0.3, 1.5, 0.3),
            position=(x, 0.75, z),
            color=color.rgb(139, 69, 19),
        )
        leaves = Entity(
            parent=trunk,
            model='cube',
            scale=(1.5, 1, 1.5),
            position=(0, 1, 0),
            color=color.green,
        )
        trees.append(trunk)
    return trees
