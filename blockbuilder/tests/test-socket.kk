module tests/test-socket

import std/num/int64
import std/time/duration

import kincaid-utils

import socket/socket
import tests/test

// TODO: Add test that returns invalid socket.

fun client-server-test()
  if socket-init() != 0 then
    Fail("Unable to initialize sockets")
  else
    val server-listen-socket = create-socket()
    val client-socket = create-socket()

    val server-addr = "127.0.0.1"
    val server-port = 5000
    if server-listen-socket.bind(server-addr, server-port) == socketError then
      Fail("Error binding server socket to address")
    else
      if server-listen-socket.listen() == socketError then
        Fail("Error listening with server socket")
      else
        sleep(0.1)

        // First client connect attempt will return errBlocking
        client-socket.connect(server-addr, server-port)
        if socket-get-last-error() != errWouldBlock then
          Fail("Client unable to connect to server")
        else

          val server-socket = server-listen-socket.accept()

          // Second attempt should report errIsConn because it succeeded
          client-socket.connect(server-addr, server-port)
          if socket-get-last-error() != errIsConn then
            Fail("Client unable to connect to server (err = " ++ socket-get-last-error().show ++ ")")
          else
            if server-socket == invalidSocket then
              Fail("Server socket didn't receive connection")
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

pub val socket-tests = Case(
  "socket",
  [
    socket-test
  ]
)