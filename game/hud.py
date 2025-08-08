from ursina import Text


class HUD:
    """Heads-up display for showing player info."""

    def __init__(self):
        self.coin_text = Text('Coins: 0', position=(-0.85, 0.45), scale=1.5)

    def update_coins(self, count: int):
        self.coin_text.text = f'Coins: {count}'
