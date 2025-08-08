from ursina import Entity, color, Text


class NPC(Entity):
    """Simple NPC represented as a colored cube."""

    def __init__(self, name: str, position, col=color.white):
        super().__init__(
            model='cube',
            color=col,
            scale=1.5,
            position=position,
            collider='box',
        )
        self.name = name
        self.label = Text(
            text=name,
            origin=(0, 0),
            scale=1.5,
            position=(0, 1.2, 0),
            parent=self,
            billboard=True,
        )
