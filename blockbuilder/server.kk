module server

import std/num/int64
import std/time/duration
import std/time/timer

import raylib/raylib
import socket/socket

import commands
import world

pub effect server-error
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


pub fun create-local-server() : <socket-io,socket-error> (server, gameWorld, int)
  val listen-socket = create-socket()
  listen-socket.bind("127.0.0.1", game-port)
  listen-socket.listen()

  val local-player = create-player(0)
  val world = GameWorld(red, [local-player])

  (LocalServer(ticks(), [], listen-socket, []), world, local-player.id)

pub fun create-remote-server(addr : string) : <socket-io,socket-error,server-error> (server, gameWorld, int)
  val new-socket = create-socket()
  new-socket.connect(addr, game-port)

  // Wait for server to send world info.
  fun get-initial-world-info(maybe-player-id = Nothing, players = [], maybe-world-color = Nothing) : _e (server, gameWorld, int)
    // TODO: We should probably have a timeout here
    // Wait for server to send data
    select([new-socket], [], [], True)

    match new-socket.read-command()
      ConnectedPlayerId(id) ->
        get-initial-world-info(Just(id), players, maybe-world-color)
      PlayerPosition(id, position) ->
        get-initial-world-info(maybe-player-id, players ++ [Player(id, position)], maybe-world-color)
      SetColor(c) -> 
        get-initial-world-info(maybe-player-id, players, Just(c))
      ServerConnectFinished ->
        val player-id = match maybe-player-id
          Nothing -> server-error("No ID received from server")
          Just(id) -> id
        
        val received-players = match players
          Nil -> server-error("No players received from server")
          _ -> players

        val world-color = match maybe-world-color
          Nothing -> server-error("No color received from server")
          Just(c) -> c

        val world = GameWorld(world-color, players)
        (RemoteServer(new-socket), world, player-id)

  get-initial-world-info()

fun accept-all-pending(s : socket, accepted : list<socket> = []) : <socket-io,socket-error> list<socket>
  match s.accept()
    Nothing -> accepted
    Just(new-socket) ->
      s.accept-all-pending(accepted ++ [new-socket])
 
pub fun update-conns(s : server, world : gameWorld) : <socket-io,socket-error> server
  match s
    RemoteServer -> s
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      val accepted = listen-socket.accept-all-pending()

      // Send player IDs and world state to each player.
      val first-id : int = world.players.map(fn(p){ p.id }).maximum + 1
      val player-ids = accepted.map-indexed(fn(i, _){i + first-id})
      
      fun send-initial-state((s, player-id))
        s.write-command(ConnectedPlayerId(player-id))
        s.write-command(SetColor(world.cube-color))
        world.players.map(fn(p){
          s.write-command(PlayerPosition(p.id, p.pos))
        })
        s.write-command(ServerConnectFinished)

      accepted.zip(player-ids).map(send-initial-state)

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
          (world(cube-color = new-color), s)

pub fun submit-cmds(s : server, cmds : list<command>) : <socket-io,socket-error> server
  match s
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      LocalServer(last-update, cmds ++ pending-cmds, listen-socket, client-sockets)
    RemoteServer(server-socket) ->
      cmds.list/foreach(fn(c){ server-socket.write-command(c) })
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
          val cmds = select-res.readable.map(fn(s){ s.read-command() })
          LocalServer(last-update, pending-cmds ++ cmds, listen-socket, client-sockets)

fun write-color(s : socket, c : color) : <socket-io,socket-error> ()
  val to-send = [c.r, c.g, c.b, c.a].map(char).vector
  val sent = s.send(to-send)
  ()

pub fun broadcast-world(s : server, prev-world : gameWorld, world : gameWorld) : <socket-io,socket-error> ()
  match s
    RemoteServer -> ()
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      // TODO: Switch this to world comparison
      if prev-world.cube-color != world.cube-color then
        client-sockets.map(fn(c){ c.write-color(world.cube-color)})
        ()
      else ()
