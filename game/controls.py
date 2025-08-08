from ursina import Vec3, time, held_keys


class FlightController:
    """Allow the player to fly a plane using WASD and vertical controls."""

    def __init__(self, player):
        self.player = player
        self.flying = False
        self.plane = None

    def mount_plane(self, plane):
        if self.player.intersects(plane).hit and not self.flying:
            self.flying = True
            self.plane = plane
            self.player.parent = plane
            self.player.position = Vec3(0, 1, 0)
            self.player.gravity = 0
            return True
        return False

    def dismount(self):
        if self.flying:
            self.flying = False
            self.player.parent = None
            self.player.gravity = 1
            if self.plane:
                self.player.position = self.plane.position + Vec3(0, 1, 0)
            return True
        return False

    def update(self):
        if not self.flying or not self.plane:
            return
        speed = 5 * time.dt
        if held_keys['w']:
            self.plane.position += Vec3(0, 0, 1) * speed
        if held_keys['s']:
            self.plane.position += Vec3(0, 0, -1) * speed
        if held_keys['a']:
            self.plane.position += Vec3(-1, 0, 0) * speed
        if held_keys['d']:
            self.plane.position += Vec3(1, 0, 0) * speed
        if held_keys['space']:
            self.plane.position += Vec3(0, 1, 0) * speed
        if held_keys['shift']:
            self.plane.position += Vec3(0, -1, 0) * speed
