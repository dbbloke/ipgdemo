from ursina import Entity, color


class Coin(Entity):
    """Collectable coin that grants the player an inventory item."""

    def __init__(self, position):
        super().__init__(
            model='cube',
            color=color.yellow,
            scale=0.5,
            position=position,
            collider='box',
        )
        self.collected = False

    def collect(self, player):
        """Collect the coin if the player touches it."""
        if not self.collected and player.intersects(self).hit:
            self.collected = True
            self.enabled = False
            player.add_item('coin')
            return True
        return False


def spawn_coins():
    """Spawn a set of coins around the map."""
    positions = [(3, 0.5, 3), (-3, 0.5, 1), (1, 0.5, -4)]
    return [Coin(p) for p in positions]
