module commands

import socket/socket

pub type command
  SwitchColor

pub fun writeCommand(s : socket, c : command) : <socket-io, socket-error> ()
  match c
    SwitchColor -> s.send([char(1)].vector)

  ()

pub fun readCommand(s : socket) : <socket-io, socket-error> command
  val result = s.recv(1)[0].int
  match result
    1 ->  SwitchColor