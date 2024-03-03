// This module contains code for simulating the game world.

module world

import std/num/float64

pub struct gameWorld
  rotation : float64

pub fun gameWorld/(==)(x : gameWorld, y: gameWorld)
  x.rotation == y.rotation

pub fun gameWorld/show(world: gameWorld)
  "GameWorld(" ++ world.rotation.show ++ ")"

val rotation-rate: float64 = 0.01

pub fun tick(world: gameWorld) : gameWorld
  world(rotation = world.rotation + rotation-rate)