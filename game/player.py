from ursina import FirstPersonController


class Player(FirstPersonController):
    """Player controller with a simple inventory."""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.inventory = []

    def add_item(self, name: str):
        """Add an item to the player's inventory."""
        self.inventory.append(name)

    def has_item(self, name: str) -> bool:
        """Check if the player has a specific item."""
        return name in self.inventory
