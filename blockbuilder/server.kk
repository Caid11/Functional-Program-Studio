module server

import std/num/ddouble
import std/num/int64
import std/time/duration
import std/time/timestamp
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

pub type session
  ClientSession(server-socket : socket)
  ServerSession(listen-socket : socket, client-sockets : list<socket>)

fun create-client-session(addr : string) : _e session
  val server-socket = create-socket()
  server-socket.connect(addr, game-port)

  ClientSession(server-socket)

fun create-server-session() : _e session
  val listen-socket = create-socket()
  listen-socket.bind("127.0.0.1", game-port)
  listen-socket.listen()

  ServerSession(listen-socket, [])

pub struct server
  last-update : duration
  pending-cmds : list<serverCommand>
  cmd-reads : list<a>
  session : session
  world : gameWorld

pub fun create-local-server() : <socket-io,socket-error> (server, int)
  val server-session = create-server-session()

  val local-player = create-player(0)
  val world = GameWorld(red, [local-player])

  (Server(ticks(), [], [], [], server-session, world), local-player.id)

pub fun create-remote-server(addr : string) : <socket-io,socket-error,server-error> (server, int)
  with ctl cmd-yield(s) server-error("unexpected cmd yield")

  val client-session = create-client-session(addr)
  val server-socket = match client-session
    ClientSession(s) -> s

  // Wait for server to send world info.
  fun get-initial-world-info(maybe-player-id = Nothing, players = [], maybe-world-color = Nothing) : _e (server, int)
    match server-socket.read-command(True)
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
        (Server(ticks(), [], [], [], client-session, world), player-id)

  val server = get-initial-world-info()

fun accept-all-pending(s : socket, accepted : list<socket> = []) : <socket-io,socket-error> list<socket>
  match s.accept()
    Nothing -> accepted
    Just(new-socket) ->
      s.accept-all-pending(accepted ++ [new-socket])
 
pub fun update-conns(server : server) : <socket-io,socket-error> server
  match server.session
    ClientSession -> server
    ServerSession(listen-socket, client-sockets) ->
      val accepted = listen-socket.accept-all-pending()

      // Send player IDs and world state to each player.
      val first-id : int = server.world.players.map(fn(p){ p.id }).maximum + 1
      val player-ids = accepted.map-indexed(fn(i, _){i + first-id})
      
      fun send-initial-state((s, player-id))
        s.write-command(ConnectedPlayerId(player-id))
        s.write-command(SetColor(server.world.cube-color))
        server.world.players.map(fn(p){
          s.write-command(PlayerPosition(p.id, p.pos))
        })
        s.write-command(ServerConnectFinished)

      accepted.zip(player-ids).map(send-initial-state)

      // Add new players to world.
      val new-players = player-ids.map(fn(i){ Player(i, Vector3(0.0, 0.0, 0.0))})
      
      val prev-world = server.world
      val new-world = prev-world(players = prev-world.players ++ new-players)

      val updated-session = ServerSession(listen-socket, client-sockets ++ accepted)

      server(session = updated-session, world = new-world)

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
  val send-sockets = match s.session
    ServerSession(_, client-sockets) -> client-sockets
    ClientSession(server-socket) -> [server-socket]

  val local-cmds = new-cmds.map(fn(c){ ServerCommand(Nothing, c)})
  val cmds = s.pending-cmds ++ local-cmds

  send-sockets.map(fn(sock){
    val to-send = cmds.filter(fn(c){
      match c.send-socket
        Nothing -> True
        Just(s) -> s != sock
    }).map(fn(c){ c.cmd })

    to-send.map(fn(c){ sock.write-command(c) })
  })
  s(pending-cmds = cmds)

fun get-cmds(s : socket, cmds = []) : <socket-io,socket-error, cmd-yield> a
  with ctl cmd-yield(s)
    (cmds, Just((s, resume)))

  val select-res = select([s], [], [], False)
  if !select-res.is-readable(s) then
    (cmds, Nothing)
  else
    val curr-cmd = ServerCommand(Just(s), s.read-command())
    s.get-cmds(cmds ++ [curr-cmd])

fun resume-in-flight(r : a) : <socket-io,socket-error, cmd-yield> a
  with ctl cmd-yield(s)
    (cmds, Just((s, resume)))

  val select-res = select([s], [], [], False)
  if !select-res.is-readable(s) then
    (cmds, Nothing)
  else
    val curr-cmd = ServerCommand(Just(s), s.read-command())
    s.get-cmds(cmds ++ [curr-cmd])


pub fun recv-cmds(s : server) : <socket-io,socket-error> server
  var in-flight-reads := []
  var in-flight-sockets := []
  with ctl cmd-yield(s)
    in-flight-reads := in-flight-reads ++ [resume]
    in-flight-sockets := in-flight-sockets ++ [s]

  val receive-sockets = match s.session
    ClientSession(server-socket) -> [server-socket]
    ServerSession(_, client-sockets) -> client-sockets

  val received-res = receive-sockets
    // Only read on sockets that don't have outstanding commands
    .filter(fn(s){ s.in-flight-sockets.index-of( fn(sock){ sock == s }) == -1 })

    // Read commands from all other sockets
    .map( fn(s){ s.get-cmds } )
    .flatmap(fn(l){ l })

  val received-cmds = received-res.flatmap( fn((cmds, _)){ cmds })

  val in-flight-pairs = received-res.filter( is-just ).map( unjust )
  val in-flight-reads = in-flight-pairs.map( fn((_,r)){ r })
  val in-flight-sockets = in-flight-pairs.map( fn((s,_)){ s })

  // Attempt to resume reading in flight commands
  val in-flight-cmds = s.in-flight-reads.map( fn(res){ res() })

  val new-pending-cmds = s.pending-cmds ++ recieved-cmds ++ in-flight-cmds 

  s(pending-cmds = new-pending-cmds, in-flight-reads = in-flight-reads, in-flight-sockets = in-flight-sockets)

pub fun apply-cmds(s : server) : <socket-io, socket-error> server
  val curr-time = ticks()
  val elapsed = ticks() - s.last-update
  val new-world = update-world(s.world, s.pending-cmds.map(fn(c){ c.cmd }), elapsed)
  s(last-update = curr-time, world = new-world, pending-cmds = [])