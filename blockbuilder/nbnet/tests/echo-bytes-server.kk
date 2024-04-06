module nbnet/tests/echo-bytes-server

import std/time

import nbnet/nbnet

import echo-bytes-shared

effect serverError
  ctl serverError(msg : string) : a

fun echo-received-message(client : connectionHandle) 
  val message-info = gameServer-getMessageInfo()

  if message-info.sender != client then serverError("Unexpected sender")
  else ()

  if message-info.ty != byteArrayMessageType then serverError("Unexpected message type")
  else ()

  val msg-bytes = nbnet-message-to-byte-vector(message-info.data)

  if gameServer-sendReliableByteArrayTo(client, msg-bytes) < 0 then serverError("Unable to send message")
  else ()

  byteArrayMessage-destroy(msg-bytes)

  ()

fun main()
  with ctl serverError(msg)
    println("ERROR: " ++ msg)

  if udp-register() < 0 then serverError("Unable to register UDP driver")
  else ()

  if gameServer-start(echo-protocol-name, echo-port) < 0 then serverError("Unable to start server")
  else ()

  var client : connectionHandle := 0

  val dt = 1.0 / echo-tick-rate

  fun server-poll()
    val event = gameServer-poll()
    match event
      ErrorEvent -> serverError("Error while polling connection state")
      NoEvent -> ()

      NewConnection ->
        if client != 0 then
          gameServer-rejectIncomingConnectionWithCode(echo-server-busy-code)
        else 
          gameServer-acceptIncomingConnection()
          client := gameServer-getIncomingConnection()
          server-poll()

      ClientDisconnected ->
        if gameServer-getDisconnectedClient() != client then
          serverError("Unrecognized client disconnected")
        else
          client := 0
          server-poll()

      ClientMessageReceived ->
        if echo-received-message(client) < 0 then
          serverError("Unable to echo received message")
        else server-poll()

  fun server-loop()
    server-poll()
    sleep(dt)
    if gameServer-sendPackets() < 0 then
      serverError("Unable to send packets")
    else ()
    server-loop()

  gameServer-stop()

  ()