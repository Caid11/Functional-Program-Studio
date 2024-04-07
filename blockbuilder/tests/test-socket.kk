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

  client-socket.connect(server-addr, server-port)
  val server-socket-maybe = server-listen-socket.accept()
  match server-socket-maybe
    Nothing -> Fail("Server didn't receive connection")
    Just(server-socket) ->
      // Wait for client to connect
      val select-res = select([], [client-socket], [client-socket], True) 
      select-res.raise-errors()

      if !select-res.is-writable(client-socket) then
        Fail("Client socket wasn't writable")
      else
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

fun socket-no-pending()
  with final ctl socket-error(msg)
    Fail("Socket error: " ++ msg)

  socket-init()

  val server-listen-socket = create-socket()

  val server-addr = "127.0.0.1"
  val server-port = 5000
  server-listen-socket.bind(server-addr, server-port)

  server-listen-socket.listen()

  val server-socket = server-listen-socket.accept()
  val result = match server-socket
    Nothing -> Success
    _ -> Fail("Accepted socket with none pending")

  server-listen-socket.close()
  socket-shutdown()
  Success 

val socket-no-pending-test = Test(
  "accept-returns-none-with-no-pending",
  socket-no-pending
)

pub val socket-tests = Case(
  "socket",
  [
    socket-test,
    socket-no-pending-test
  ]
)