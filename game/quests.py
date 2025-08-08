class QuestManager:
    """Handles multi-stage quest progression."""

    def __init__(self, instruction_text):
        self.stage = 0
        self.instruction_text = instruction_text
        self.coins_needed = 3

    def start(self):
        self.stage = 0
        self.instruction_text.text = 'Find Bob to start your quest'

    def collect_coin(self, player):
        """Check coin progress and advance the quest."""
        if self.stage == 1 and self.count_coins(player) >= self.coins_needed:
            self.stage = 2
            self.instruction_text.text = 'Return to Bob with the coins.'

    def count_coins(self, player) -> int:
        return player.inventory.count('coin')

    def interact_with_npc(self, player, npc):
        """Update quest state when the player interacts with an NPC."""
        if npc.name == 'Bob' and self.stage == 0 and player.intersects(npc).hit:
            self.stage = 1
            self.instruction_text.text = 'Bob: Collect 3 coins hidden in the city.'
            return True
        if npc.name == 'Bob' and self.stage == 2 and player.intersects(npc).hit:
            self.stage = 3
            self.instruction_text.text = 'Bob: Great! Take them to Alice.'
            return True
        if npc.name == 'Alice' and self.stage == 3 and player.intersects(npc).hit:
            self.stage = 4
            self.instruction_text.text = 'Alice: Thanks for the coins! Quest complete.'
            return True
        return False
