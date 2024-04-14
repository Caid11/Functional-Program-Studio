module tests/test-socket

import std/num/int64
import std/num/float64
import std/time/duration

import kincaid-utils

import socket/socket
import tests/test

// TODO: Add test that returns invalid socket.

fun client-server-test()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  socket-init()

  val server-listen-socket = create-socket()
  val client-socket = create-socket()

  val server-addr = "127.0.0.1"
  val server-port = 5000
  server-listen-socket.bind(server-addr, server-port)

  server-listen-socket.listen()

  client-socket.connect(server-addr, server-port)
  val server-socket : socket = match server-listen-socket.accept()
    Nothing -> test-fail("Server didn't receive connection")
    Just(s) -> s

  // Wait for client to connect
  val select-res = select([], [client-socket], [client-socket], True) 
  select-res.raise-errors()

  if !select-res.is-writable(client-socket) then
    test-fail("Client socket wasn't writable")
  else ()

  val msg = "hello"

  client-socket.send(msg.vector)

  val res = server-socket.recv(msg.count)

  if res.ks-string != msg then
    test-fail("Server received bad message (" ++ res.string ++ ")")
  else ()

  server-socket.shutdown()

  server-socket.close()
  server-listen-socket.close()
  client-socket.close()

  socket-shutdown()

val socket-test = Test(
  "socket",
  client-server-test
)

fun socket-no-pending()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  socket-init()

  val server-listen-socket = create-socket()

  val server-addr = "127.0.0.1"
  val server-port = 5000
  server-listen-socket.bind(server-addr, server-port)

  server-listen-socket.listen()

  match server-listen-socket.accept()
    Nothing -> ()
    _ -> test-fail("Accepted socket with none pending")

  server-listen-socket.close()
  socket-shutdown()

val socket-no-pending-test = Test(
  "accept-returns-none-with-no-pending",
  socket-no-pending
)

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

fun send-recv-char()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val msg = 'h'

  client-socket.send(msg)

  val res : char = server-socket.recv()

  if res != msg then
    test-fail("Server received bad message (" ++ res.show ++ ")")
  else ()

val send-recv-char-test = Test(
  "send-recv-char",
  send-recv-char
)

fun send-recv-int()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val msg : int = 1234567

  client-socket.send(msg)

  val res : int = server-socket.recv()

  if res != msg then
    test-fail("Server received bad message (" ++ res.show ++ ")")
  else ()

val send-recv-int-test = Test(
  "send-recv-int",
  send-recv-int
)

fun send-recv-float64()
  with final ctl socket-error(cmd, msg)
    test-fail("Socket error: (" ++ cmd ++ ")" ++ msg)

  val (client-socket, server-socket) = make-test-sockets()
  with finally{ close-test-sockets(client-socket, server-socket) }

  val msg : float64 = 5.2

  client-socket.send(msg)

  val res : float64 = server-socket.recv()

  if res != msg then
    test-fail("Server received bad message (" ++ res.show ++ ")")
  else ()

val send-recv-float64-test = Test(
  "send-recv-float64",
  send-recv-float64
)

pub val socket-tests = Case(
  "socket",
  [
    socket-test,
    socket-no-pending-test,
    send-recv-char-test,
    send-recv-int-test,
    send-recv-float64-test
  ]
)