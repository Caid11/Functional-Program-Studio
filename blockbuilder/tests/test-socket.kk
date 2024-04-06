module tests/test-socket

import std/num/int64
import std/time/duration

import kincaid-utils

import socket/socket
import tests/test

// TODO: Add test that returns invalid socket.

fun client-server-test()
  with final ctl socket-error(msg)
    Fail("Socket error: " ++ msg)

  socket-init()

  val server-listen-socket = create-socket()
  val client-socket = create-socket()

  val server-addr = "127.0.0.1"
  val server-port = 5000
  server-listen-socket.bind(server-addr, server-port)

  server-listen-socket.listen()
  sleep(0.1)

  // First client connect attempt will return errBlocking
  client-socket.connect(server-addr, server-port)
  sleep(0.4)

  val server-socket = server-listen-socket.accept()

  // TODO: Call select() instead of sleeping

  val msg = "hello"

  client-socket.send(msg.vector)

  val res = server-socket.recv(msg.count)

  if res.ks-string != msg then
    Fail("Server received bad message (" ++ res.string ++ ")")
  else
    server-socket.shutdown()

    server-socket.close()
    server-listen-socket.close()
    client-socket.close()

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