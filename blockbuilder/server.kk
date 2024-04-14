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

struct serverCommand
  send-socket : maybe<socket>
  cmd : command

fun serverCommand/show(c : serverCommand)
  val socket-str = match c.send-socket
    Nothing -> "None"
    Just(s) -> s.show
  "[" ++ socket-str ++ " " ++ c.cmd.show ++ "]"

pub type server
  LocalServer(last-update : duration, pending-cmds : list<serverCommand>, listen-socket : socket, client-sockets : list<socket>)
  RemoteServer(last-update : duration, socket : socket, pending-cmds : list<serverCommand>)

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
        (RemoteServer(ticks(), new-socket, []), world, player-id)

  get-initial-world-info()

fun accept-all-pending(s : socket, accepted : list<socket> = []) : <socket-io,socket-error> list<socket>
  match s.accept()
    Nothing -> accepted
    Just(new-socket) ->
      s.accept-all-pending(accepted ++ [new-socket])
 
pub fun update-conns(s : server, world : gameWorld) : <socket-io,socket-error> (gameWorld, server)
  match s
    RemoteServer -> (world, s)
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

      // Add new players to world.
      val new-players = player-ids.map(fn(i){ Player(i, Vector3(0.0, 0.0, 0.0))})
      val new-world = world(players = world.players ++ new-players)

      (new-world, LocalServer(last-update, pending-cmds, listen-socket, client-sockets ++ accepted))

fun update-world(world : gameWorld, cmds : list<command>, elapsed : duration)
  if elapsed <= ms-per-update then world
  else
    val (new-world,new-cmds) = world.tick(cmds)
    val new-elapsed = elapsed - ms-per-update
    update-world(new-world, new-cmds, new-elapsed)

fun read-color(s : socket) : <socket-io,socket-error> color
  val color-bytes = s.recv(4).vector/map(int)
  Color(color-bytes[0], color-bytes[1], color-bytes[2], color-bytes[3])

pub fun send-cmds(s : server, new-cmds : list<command>) : <socket-io,socket-error> server
  match s
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      val local-cmds = new-cmds.map(fn(c){ ServerCommand(Nothing, c)})
      val cmds = pending-cmds ++ local-cmds

      client-sockets.map(fn(client-sock){
        val to-send = cmds.filter(fn(c){
          match c.send-socket
            Nothing -> True
            Just(sock) -> sock != client-sock
        }).map(fn(c){ c.cmd })

        to-send.map(fn(c){ client-sock.write-command(c) })
      })
      LocalServer(last-update, cmds, listen-socket, client-sockets)

    RemoteServer(last-update, server-socket, pending-cmds) ->
      val local-cmds = new-cmds.map(fn(c){ ServerCommand(Nothing, c)})
      val cmds = pending-cmds ++ local-cmds

      val to-send = cmds.filter(fn(c){
        match c.send-socket
          Nothing -> True
          Just(sock) -> sock != server-socket
      }).map(fn(c){ c.cmd })
      to-send.map(fn(c){ server-socket.write-command(c) })

      RemoteServer(last-update, server-socket, cmds)

fun get-cmds(s : socket, cmds = []) : <socket-io,socket-error> list<serverCommand>
  val select-res = select([s], [], [], False)
  if !select-res.is-readable(s) then
    cmds
  else
    val curr-cmd = ServerCommand(Just(s), s.read-command())
    s.get-cmds(cmds ++ [curr-cmd])

pub fun recv-cmds(s : server) : <socket-io,socket-error> server
  match s
    RemoteServer(last-update, server-socket, pending-cmds) -> 
      val cmds = server-socket.get-cmds()
      RemoteServer(last-update, server-socket, pending-cmds ++ cmds)
    LocalServer(last-update, pending-cmds, listen-socket, client-sockets) ->
      match client-sockets
        Nil -> s
        _ ->
          val cmds = client-sockets.map( fn(s){ s.get-cmds } ).flatmap(fn(l){ l })
          LocalServer(last-update, pending-cmds ++ cmds, listen-socket, client-sockets)

pub fun apply-cmds(s : server, prev-world : gameWorld) : <socket-io, socket-error> (gameWorld, server)
   match s
    LocalServer(last-update, cmds, listen-socket, client-sockets) ->
      val curr-time = ticks()
      val elapsed = curr-time - last-update
      val new-world = update-world(prev-world, cmds.map(fn(c){ c.cmd }), elapsed)
      (new-world, LocalServer(curr-time, [], listen-socket, client-sockets))

    RemoteServer(last-update, server-socket, pending-cmds) ->
      val curr-time = ticks()
      val elapsed = curr-time - last-update
      val new-world = update-world(prev-world, pending-cmds.map(fn(c){ c.cmd }), elapsed)
      (new-world, RemoteServer(curr-time, server-socket, []))