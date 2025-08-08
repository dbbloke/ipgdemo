from ursina import *

from game.environment import create_ground, create_city, create_trees
from game.npc import NPC
from game.plane import create_plane
from game.quests import QuestManager
from game.controls import FlightController
from game.player import Player
from game.items import spawn_coins
from game.hud import HUD


def main():
    app = Ursina()

    window.title = '3D Adventure Game'
    window.borderless = False
    window.exit_button.visible = False

    # player controller with inventory
    player = Player()
    player.cursor.visible = False

    # environment
    create_ground()
    create_city()
    create_trees()

    # coins
    coins = spawn_coins()

    # NPCs
    bob = NPC('Bob', (2, 0.75, 2), color.orange)
    alice = NPC('Alice', (-2, 0.75, -2), color.lime)

    # plane entity
    plane = create_plane()

    instruction = Text('', position=(-0.5, 0.4), origin=(-0.5, 0), scale=2)
    quests = QuestManager(instruction)
    quests.start()

    hud = HUD()
    flight = FlightController(player)

    def input(key):
        if key == 'e':
            if quests.interact_with_npc(player, bob):
                pass
            elif quests.interact_with_npc(player, alice):
                pass
        if key == 'p':
            if flight.mount_plane(plane):
                instruction.text = 'Use WASD to fly. Space/Shift move vertically. Press Q to exit.'
        if key == 'q':
            if flight.dismount():
                instruction.text = 'Back on foot.'

    def update():
        flight.update()
        for coin in coins:
            if coin.collect(player):
                hud.update_coins(quests.count_coins(player))
                quests.collect_coin(player)

    app.run()


if __name__ == '__main__':
    main()
