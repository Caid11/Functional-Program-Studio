// This module contains code for simulating the game world.

module world

import std/num/float64
import std/time/duration

import commands

pub struct gameWorld
  rotation : float64 = 0.0

pub fun gameWorld/(==)(x : gameWorld, y: gameWorld)
  x.rotation == y.rotation

pub fun gameWorld/show(world: gameWorld)
  "GameWorld(" ++ world.rotation.show ++ ")"

val rotation-rate: float64 = 0.01

pub val ms-per-update = duration(1.0 / 60.0)

pub fun tick(world: gameWorld, cmds : list<command>) : gameWorld
  world(rotation = world.rotation + rotation-rate)