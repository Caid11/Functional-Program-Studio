module tests/test-commands

import commands

import raylib/raylib
import socket/socket

import tests/test

fun make-test-sockets()
  socket-init()

  val listen-socket = create-socket()
  val server-socket = create-socket()

  val server-addr = "127.0.0.1"
  val server-port = 5000
  listen-socket.bind(server-addr, server-port)

  listen-socket.listen()

  server-socket.connect(server-addr, server-port)
  val client-socket : socket = match listen-socket.accept()
    Nothing -> test-fail("Server didn't receive connection")
    Just(s) -> s

  // Wait for client to connect
  val select-res = select([], [server-socket], [server-socket], True) 
  select-res.raise-errors()

  listen-socket.close()

  (client-socket, server-socket)

fun close-test-sockets(client-socket, server-socket)
  client-socket.shutdown()
  client-socket.close()

  server-socket.close()

  socket-shutdown()

fun send-recv-connectedPlayerId()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  with final ctl cmd-yield()
    test-fail("Didn't expect command yield.")
  
  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val command = ConnectedPlayerId(5)

  client-socket.write-command(command)

  val res = server-socket.read-command(True)

  if res != command then
    test-fail("Bad command received (" ++ res.show ++ ")")
  else ()

val send-recv-connectedPlayerId-test = Test(
  "send-recv-connectedPlayerId",
  send-recv-connectedPlayerId
)

fun send-recv-PlayerPosition()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  with final ctl cmd-yield()
    test-fail("Didn't expect command yield.")
  
  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val command = PlayerPosition(5, Vector3(1.0, 2.0, 3.0))

  client-socket.write-command(command)

  val res = server-socket.read-command(True)
  if res != command then
    test-fail("Bad command received (" ++ res.show ++ ")")
  else ()

val send-recv-PlayerPosition-test = Test(
  "send-recv-PlayerPosition",
  send-recv-PlayerPosition
)

fun send-recv-PlayerPositionWithYield()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val command = PlayerPosition(5, Vector3(1.0, 2.0, 3.0))

  var cmd-yielded := False
  with ctl cmd-yield()
    if cmd-yielded then test-fail("Command should only have yielded once")
    else cmd-yielded := True

    client-socket.write-command(command)
    resume(())

  // This should yield, then the effect handler should write the command
  val res = server-socket.read-command(False)

  if res != command then
    test-fail("Bad command received (" ++ res.show ++ ")")
  else ()

val send-recv-PlayerPositionWithYield-test = Test(
  "send-recv-PlayerPositionWithYield",
  send-recv-PlayerPositionWithYield
)

fun send-recv-serverConnectFinished()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  with final ctl cmd-yield()
    test-fail("Didn't expect command yield.")
  
  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val command = ServerConnectFinished

  client-socket.write-command(command)

  val res = server-socket.read-command(True)

  if res != command then
    test-fail("Bad command received (" ++ res.show ++ ")")
  else ()

val send-recv-serverConnectFinished-test = Test(
  "send-recv-serverConnectFinished",
  send-recv-serverConnectFinished
)

pub val command-tests = Case(
  "command",
  [
    send-recv-serverConnectFinished-test,
    send-recv-connectedPlayerId-test,
    send-recv-PlayerPosition-test,
    send-recv-PlayerPositionWithYield-test
  ]
)