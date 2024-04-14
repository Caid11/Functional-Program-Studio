module commands

import raylib/raylib
import socket/socket

pub type command
  ConnectedPlayerId(id : int)
  PlayerPosition(id : int, position : vector3)
  SetColor(c : color)
  ServerConnectFinished

pub fun command/(==)(x : command, y : command)
  match x
    ConnectedPlayerId(id-x) ->
      match y
        ConnectedPlayerId(id-y) ->
          id-x == id-y
        _ -> False

    PlayerPosition(id-x, position-x) ->
      match y
        PlayerPosition(id-y, position-y) ->
          id-x == id-y && position-x == position-y
        _ -> False

    SetColor(color-x) ->
      match y
        SetColor(color-y) ->
          color-x == color-y
        _ -> False

    ServerConnectFinished ->
      match y
        ServerConnectFinished -> True
        _ -> False

pub fun command/show(c : command)
  match c
    ConnectedPlayerId(id) -> "ConnectedPlayerId(" ++ id.show ++ ")"
    PlayerPosition(id, position) -> "PlayerPosition(" ++ id.show ++ ", " ++ position.show ++ ")"
    SetColor(c) -> "SetColor(" ++ c.show ++ ")"
    ServerConnectFinished -> "ServerConnectFinished"

pub fun get-id(c : command) : char
  val id = match c
    ConnectedPlayerId -> 1
    PlayerPosition -> 2
    SetColor -> 3
    ServerConnectFinished -> 4
  id.char

pub fun write-command(s : socket, c : command) : <socket-io, socket-error> ()
  s.send(c.get-id())

  match c
    ConnectedPlayerId(id) ->
      s.send(id)
      ()
    PlayerPosition(id, position) ->
       s.send(id)
       s.send(position.x)
       s.send(position.y)
       s.send(position.z)
       ()
    SetColor(Color(r, g, b, a)) ->
      s.send(r)
      s.send(g)
      s.send(b)
      s.send(a)
      ()
    ServerConnectFinished -> ()

  ()


pub fun read-command(s : socket) : <socket-io, socket-error> command
  // TODO: Calling select for every recv is messy

  select([s], [], [], True)
  val command-id : char = s.recv()

  match command-id.int
    1 ->
      select([s], [], [], True)
      val player-id : int = s.recv()
      ConnectedPlayerId(player-id)
    2 ->
      select([s], [], [], True)
      val player-id : int = s.recv()

      select([s], [], [], True)
      val pos-x : float64 = s.recv()
      select([s], [], [], True)
      val pos-y : float64 = s.recv()
      select([s], [], [], True)
      val pos-z : float64 = s.recv()

      PlayerPosition(player-id, Vector3(pos-x, pos-y, pos-z))

    3 ->
      select([s], [], [], True)
      val r : int = s.recv()
      select([s], [], [], True)
      val g : int = s.recv()
      select([s], [], [], True)
      val b : int = s.recv()
      select([s], [], [], True)
      val a : int = s.recv()

      SetColor(Color(r, g, b, a))

    4 -> ServerConnectFinished