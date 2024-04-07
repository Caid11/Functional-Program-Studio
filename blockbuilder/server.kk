module server

import std/time/duration
import std/time/timer

import commands
import world

pub type server
  LocalServer(last-update : duration, pending-cmds : list<command>)
  RemoteServer(addr : string)

fun update-world(world : gameWorld, cmds : list<command>, elapsed : duration)
  if elapsed <= ms-per-update then world
  else
    val (new-world,new-cmds) = world.tick(cmds)
    val new-elapsed = elapsed - ms-per-update
    update-world(new-world, new-cmds, new-elapsed)

pub fun get-updated(s : server, world : gameWorld)
  match s
    LocalServer(last-update, cmds) ->
      val curr-time = ticks()
      val elapsed = curr-time - last-update
      val new-world = update-world(world, cmds, elapsed)
      (new-world, LocalServer(curr-time, []))

pub fun submit-cmds(s : server, cmds : list<command>) : pure server
  match s
    LocalServer(last-update, pending-cmds) -> LocalServer(last-update, cmds ++ pending-cmds)

pub fun poll-cmds(s : server) : server
  // TODO
  s

pub fun broadcast-cmds(s : server) : ()
  ()