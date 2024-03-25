import std/num/int64

alias socket-io = io

alias socket = int64

extern import
  c { syslib = "Ws2_32" }

extern import
  c file "socket-inline.c"

extern socket-init() : socket-io int
  c "kk_socket_socket_init"

pub fun socket-shutdown() : socket-io ()
  ()

extern create-socket() : socket-io socket
  c "kk_socket_create_socket"

extern bind(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_bind"

extern listen(socket : socket) : socket-io int
  c "kk_socket_listen"

pub fun accept(socket : socket) : socket-io maybe<socket>
  Nothing

pub fun connect(socket : socket, address : string, port : int) : socket-io ()
  ()

pub fun close(socket : socket) : socket-io ()
  ()

pub fun recv(socket : socket, num-bytes : int) : socket-io vector<char>
  [].vector

pub fun send(socket : socket, bytes : vector<char>) : socket-io ()
  ()

pub fun shutdown(socket : socket) : socket-io ()
  ()