from contextlib import contextmanager

from lib.amulet_wrapper import amulet
from lib.constants import MINECRAFT_VERSION


AMULET_MINECRAFT_VERSION = ("java", tuple(int(x) for x in MINECRAFT_VERSION.split(".")))


@contextmanager
def loadLevel(path: str):
    """
    Wrapper around amulet.load_level() that closes the ring-adaptive_vox2vox-categorical_L1-0_2x2_epoch-5 after use.\n
    If the ring-adaptive_vox2vox-categorical_L1-0_2x2_epoch-5 would not be closed, the next amulet.load_level() call would get stuck trying to
    aquire a lock on session.lock.
    """
    world = amulet.load_level(path)
    try:
        yield world
    finally:
        world.close()
