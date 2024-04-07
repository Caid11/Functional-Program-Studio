module server

import std/num/int64
import std/time/duration
import std/time/timer

import raylib/raylib
import socket/socket

import commands
import world

effect server-error
  ctl server-error(msg : string) : a

// DOOM uses 666, and I'm pretty sure no one will be running that.
val game-port = 666

pub type server
  LocalServer(last-update : duration, pending-cmds : list<command>, listen-socket : socket, client-sockets : list<socket>)
  RemoteServer(socket : socket)

pub fun print-client-sockets(s : server)
  match s
    RemoteServer -> ()
    LocalServer(_, _, _, sockets) ->
      val socket-str = sockets.map(show).join(" ")
      println(socket-str)


pub fun create-local-server() : <socket-io,socket-error> server
  val listen-socket = create-socket()
  listen-socket.bind("127.0.0.1", game-port)
  listen-socket.listen()

  LocalServer(ticks(), [], listen-socket, [])

pub fun create-remote-server(addr : string) : <socket-io,socket-error> server
  val new-socket = create-socket()
  new-socket.connect(addr, game-port)
  RemoteServer(new-socket)

fun accept-all-pending(s : socket, accepted : list<socket> = []) : <socket-io,socket-error> list<socket>
  match s.accept()
    Nothing -> accepted
    Just(new-socket) ->
      s.accept-all-pending(accepted ++ [new-socket])
 
pub fun update-conns(s : server) : <socket-io,socket-error> server
  match s
    RemoteServer -> s
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      val accepted = listen-socket.accept-all-pending()
      LocalServer(last-update, pending-cmds, listen-socket, client-sockets ++ accepted)

fun update-world(world : gameWorld, cmds : list<command>, elapsed : duration)
  if elapsed <= ms-per-update then world
  else
    val (new-world,new-cmds) = world.tick(cmds)
    val new-elapsed = elapsed - ms-per-update
    update-world(new-world, new-cmds, new-elapsed)

fun read-color(s : socket) : <socket-io,socket-error> color
  val color-bytes = s.recv(4).vector/map(int)
  Color(color-bytes[0], color-bytes[1], color-bytes[2], color-bytes[3])

pub fun get-updated(s : server, world : gameWorld)
  match s
    LocalServer(last-update, cmds, listen-socket, client-sockets) ->
      val curr-time = ticks()
      val elapsed = curr-time - last-update
      val new-world = update-world(world, cmds, elapsed)
      (new-world, LocalServer(curr-time, [], listen-socket, client-sockets))

    RemoteServer(server-socket) ->
      // Check for updates from server.
      val select-res = select([server-socket], [], [], False)
      match select-res.readable
        Nil ->
          (world, s)
        _ ->
          val new-color = server-socket.read-color()
          (world(color = new-color), s)

pub fun submit-cmds(s : server, cmds : list<command>) : <socket-io,socket-error> server
  match s
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      LocalServer(last-update, cmds ++ pending-cmds, listen-socket, client-sockets)
    RemoteServer(server-socket) ->
      cmds.list/foreach(fn(c){ server-socket.writeCommand(c) })
      s

pub fun poll-cmds(s : server) : <socket-io,socket-error> server
  match s
    RemoteServer -> s
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      match client-sockets
        Nil -> s
        _ ->
          // Check for any clients that are readable
          val select-res = select(client-sockets, [], [], False)

          // Collect commands from any readable sockets.
          val cmds = select-res.readable.map(fn(s){ s.readCommand() })
          LocalServer(last-update, pending-cmds ++ cmds, listen-socket, client-sockets)

fun write-color(s : socket, c : color) : <socket-io,socket-error> ()
  val to-send = [c.r, c.g, c.b, c.a].map(char).vector
  val sent = s.send(to-send)
  ()

pub fun broadcast-world(s : server, world : gameWorld) : <socket-io,socket-error> ()
  match s
    RemoteServer -> ()
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      client-sockets.map(fn(c){ c.write-color(world.color)})
      ()
