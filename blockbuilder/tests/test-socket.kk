module tests/test-socket

import socket/socket
import tests/test

fun client-server-test()
  if socket-init() != 0 then
    Fail("Unable to initialize sockets")
  else
    val server-listen-socket = create-socket()
    val client-socket = create-socket()

    val server-addr = "127.0.0.1"
    val server-port = 5000
    server-listen-socket.bind(server-addr, server-port)

    server-listen-socket.listen()

    client-socket.connect(server-addr, server-port)

    val server-socket-maybe = server-listen-socket.accept()
    match server-socket-maybe
      Nothing -> Fail("Server socket didn't receive connection")
      Just(server-socket) ->
        val msg = "hello"

        client-socket.send(msg.vector)

        val res = server-socket.recv(msg.count)

        if res.string != msg then
          Fail("Server received bad message")
        else
          server-socket.shutdown()
          socket-shutdown()
          Success 

val socket-test = Test(
  "socket",
  client-server-test
)

pub val socket-tests = Case(
  "socket",
  [
    socket-test
  ]
)