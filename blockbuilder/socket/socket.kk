module socket/socket

import std/num/int64

alias socket-io = io

pub effect socket-error
  ctl socket-error(msg : string) : a

alias socket = int64

struct selectResult
  readable : list<socket>
  writable : list<socket>
  errored : list<socket>

pub val socketError = -1
pub val invalidSocket : int64 = int64(-1)

pub val errWouldBlock = 10035
pub val errIsConn     = 10056

extern import
  c { syslib = "Ws2_32" }

extern import
  c file "socket-inline.c"

extern c-socket-init() : socket-io int
  c "kk_socket_socket_init"

pub fun socket-init() : <socket-io,socket-error> ()
  val result = c-socket-init()
  if result != 0 then
    socket-error(c-socket-get-error-string(result))
  else ()

extern c-socket-shutdown() : socket-io int
  c "kk_socket_socket_shutdown"

pub fun socket-shutdown() : <socket-io,socket-error> ()
  val result = c-socket-shutdown()
  if result != 0 then
    socket-error(c-socket-get-error-string(result))
  else ()

extern c-socket-get-last-error() : socket-io int
  c "kk_socket_socket_get_last_error"

extern c-socket-get-error-string(err : int) : socket-io string
  c "kk_socket_socket_get_error_string"

fun get-last-error-string() : socket-io string
  c-socket-get-error-string(c-socket-get-last-error())

extern c-create-socket() : socket-io socket
  c "kk_socket_create_socket"

pub fun create-socket() : <socket-io,socket-error> socket
  val result = c-create-socket()
  if result == invalidSocket then
    socket-error(get-last-error-string())
  else result

extern c-bind(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_bind"

pub fun bind(socket : socket, address : string, port : int) : <socket-io,socket-error> ()
  if c-bind(socket, address, port) == socketError then
    socket-error(get-last-error-string())
  else ()

extern c-listen(socket : socket) : socket-io int
  c "kk_socket_listen"

pub fun listen(socket : socket) : <socket-io,socket-error> ()
  if c-listen(socket) == socketError then
    socket-error(get-last-error-string())
  else ()

extern c-accept(socket : socket) : socket-io socket
  c "kk_socket_accept"

pub fun accept(socket : socket) : <socket-io,socket-error> socket
  val result = c-accept(socket)
  if result == invalidSocket then
    socket-error(get-last-error-string())
  else result

extern c-connect(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_connect"

pub fun connect(socket : socket, address : string, port : int) : <socket-io,socket-error> ()
  if c-connect(socket, address, port) == socketError then 
    val lastError = c-socket-get-last-error()
    if lastError == errWouldBlock then ()
    else
      socket-error(c-socket-get-error-string(lastError))
  else ()

extern c-close(socket : socket) : socket-io int
  c "kk_socket_close"

pub fun close(socket : socket) : <socket-io,socket-error> ()
  if c-close(socket) == socketError then
    socket-error(get-last-error-string())
  else ()

extern c-send(socket : socket, bytes : vector<char>) : socket-io int
  c "kk_socket_send"

pub fun send(socket : socket, bytes : vector<char>) : <socket-io,socket-error> int
  val result = c-send(socket, bytes)
  if result == socketError then
    socket-error(get-last-error-string())
  else result

extern c-recv(socket : socket, num-bytes : int) : socket-io (int,vector<char>)
  c "kk_socket_recv"

pub fun recv(socket : socket, num-bytes : int) : <socket-io,socket-error> vector<char>
  val (res, bytes) = c-recv(socket, num-bytes)
  if res == socketError then
    socket-error(get-last-error-string())
  else bytes

extern c-shutdown(socket : socket) : socket-io int
  c "kk_socket_shutdown"

pub fun shutdown(socket : socket) : <socket-io,socket-error> ()
  if c-shutdown(socket) == socketError then
    socket-error(get-last-error-string())
  else ()

extern c-select(readable : list<socket>,
                writable : list<socket>,
                errored : list<socket>,
                block : bool) : socket-io (int,selectResult)
  c "kk_socket_select"

pub fun select(readable : list<socket>,
               writable : list<socket>,
               errored : list<socket>,
               block : bool) : <socket-io,socket-error> selectResult
  val (res, fds) = c-select(readable, writable, errored, block)
  if res == socketError then
    socket-error(get-last-error-string())
  else fds

pub fun is-readable(result : selectResult, socket : socket) : bool
  return result.readable.index-of(fn(s){ s == socket }) != -1

pub fun is-writable(result : selectResult, socket : socket) : bool
  return result.writable.index-of(fn(s){ s == socket }) != -1

pub fun is-errored(result : selectResult, socket : socket) : bool
  return result.errored.index-of(fn(s){ s == socket }) != -1

pub fun raise-errors(result : selectResult) : <socket-io,socket-error> ()
  if !result.errored.is-empty then
    socket-error(get-last-error-string())
  else ()