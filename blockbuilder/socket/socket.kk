import std/num/int64

alias socket-io = io

alias socket = int64

pub val socketError = -1
pub val invalidSocket : int64 = int64(-1)

pub val errWouldBlock = 10035
pub val errIsConn     = 10056

extern import
  c { syslib = "Ws2_32" }

extern import
  c file "socket-inline.c"

extern socket-init() : socket-io int
  c "kk_socket_socket_init"

extern socket-shutdown() : socket-io int
  c "kk_socket_socket_shutdown"

extern socket-get-last-error() : socket-io int
  c "kk_socket_socket_get_last_error"

extern create-socket() : socket-io socket
  c "kk_socket_create_socket"

extern bind(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_bind"

extern listen(socket : socket) : socket-io int
  c "kk_socket_listen"

extern accept(socket : socket) : socket-io socket
  c "kk_socket_accept"

extern connect(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_connect"

extern close(socket : socket) : socket-io int
  c "kk_socket_close"

extern send(socket : socket, bytes : vector<char>) : socket-io int
  c "kk_socket_send"

extern recv(socket : socket, num-bytes : int) : socket-io vector<char>
  c "kk_socket_recv"

extern shutdown(socket : socket) : socket-io int
  c "kk_socket_shutdown"