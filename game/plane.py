from ursina import Entity, color


def create_plane(position=(0, 1, 5)):
    """Create a simple plane model with a front propeller."""
    plane = Entity(
        model='cube',
        color=color.azure,
        scale=(2, 0.5, 2),
        position=position,
        collider='box',
    )
    Entity(
        parent=plane,
        model='cube',
        color=color.black,
        scale=(0.1, 0.1, 1),
        position=(0, 0, 1.1),
    )
    return plane
