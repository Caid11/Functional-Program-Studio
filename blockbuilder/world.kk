// This module contains code for simulating the game world.

module world

import std/num/float64
import std/time/duration

import raylib/raylib

import commands

pub struct gameWorld
  rotation : float64 = 0.0
  color : color = red

pub fun gameWorld/(==)(x : gameWorld, y: gameWorld)
  x.rotation == y.rotation

pub fun gameWorld/show(world: gameWorld)
  "GameWorld(" ++ world.rotation.show ++ ")"

pub val ms-per-update = duration(1.0 / 60.0)

val rotation-rate : float64 = 0.01

// TODO: May have to add list of preserved cmds (e.g. movement)
pub fun tick(world: gameWorld, cmds : list<command>) : raylib-io (gameWorld, new-cmds : list<command>)
  match cmds
    Nil -> (world(rotation = world.rotation + rotation-rate), cmds)
    Cons(c, cs) ->
      match c
        SwitchColor -> 
          val new-color = match world.color
            Color(230, 41, 55, 255) -> Color(0, 228, 48, 255)
            Color(0, 228, 48, 255) -> Color(230, 41, 55, 255)
          tick(world(color = new-color), cs)