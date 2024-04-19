// This module contains code for simulating the game world.

module world

import std/num/float64
import std/time/duration

import raylib/raylib

import commands

pub struct player
  id : int
  pos : vector3

pub fun create-player(id : int) : player
  Player(id, Vector3(0.0, 0.0, 0.0))

pub struct gameWorld
  cube-color : color = red
  players : list<player> = []

fun move-player(players : list<player>, player-id, pos)
  players.map(fn(p : player){
    if p.player/id == player-id then
      p(pos = pos)
    else p
  })

// pub fun gameWorld/(==)(x : gameWorld, y: gameWorld)
//   x.rotation == y.rotation
// 
// pub fun gameWorld/show(world: gameWorld)
//   "GameWorld(" ++ world.rotation.show ++ ")"

// pub val ms-per-update = duration(1.0 / 60.0)
pub val ms-per-update : float64 = 1.0 / 60.0

val rotation-rate : float64 = 0.01

// TODO: May have to add list of preserved cmds (e.g. movement)
pub fun tick(world: gameWorld, cmds : list<command>) : raylib-io (gameWorld, new-cmds : list<command>)
  match cmds
    Nil -> (world, [])
    Cons(c, cs) ->
      match c
        SetColor(new-color) -> 
          tick(world(cube-color = new-color), cs)
        PlayerPosition(id, pos) ->
          val players = world.players.move-player(id, pos)
          tick(world(players = players), cs)