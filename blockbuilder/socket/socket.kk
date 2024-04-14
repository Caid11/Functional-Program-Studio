module socket/socket

import std/num/int64

pub alias socket-io = io

pub effect socket-error
  ctl socket-error(cmd : string, msg : string) : a

pub alias socket = int64

pub struct selectResult
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
    socket-error("socket-init", c-socket-get-error-string(result))
  else ()

extern c-socket-shutdown() : socket-io int
  c "kk_socket_socket_shutdown"

pub fun socket-shutdown() : <socket-io,socket-error> ()
  val result = c-socket-shutdown()
  if result != 0 then
    socket-error("socket-shutdown", c-socket-get-error-string(result))
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
    socket-error("create-socket", get-last-error-string())
  else result

extern c-bind(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_bind"

pub fun bind(socket : socket, address : string, port : int) : <socket-io,socket-error> ()
  if c-bind(socket, address, port) == socketError then
    socket-error("bind", get-last-error-string())
  else ()

extern c-listen(socket : socket) : socket-io int
  c "kk_socket_listen"

pub fun listen(socket : socket) : <socket-io,socket-error> ()
  if c-listen(socket) == socketError then
    socket-error("listen", get-last-error-string())
  else ()

extern c-accept(socket : socket) : socket-io socket
  c "kk_socket_accept"

pub fun accept(socket : socket) : <socket-io,socket-error> maybe<socket>
  val result = c-accept(socket)
  if result == invalidSocket then
    val lastError = c-socket-get-last-error()
    if lastError == errWouldBlock then Nothing
    else
      socket-error("accept", c-socket-get-error-string(lastError))
  else Just(result)

extern c-connect(socket : socket, address : string, port : int) : socket-io int
  c "kk_socket_connect"

pub fun connect(socket : socket, address : string, port : int) : <socket-io,socket-error> ()
  if c-connect(socket, address, port) == socketError then 
    val lastError = c-socket-get-last-error()
    if lastError == errWouldBlock then ()
    else
      socket-error("connect", c-socket-get-error-string(lastError))
  else ()

extern c-close(socket : socket) : socket-io int
  c "kk_socket_close"

pub fun close(socket : socket) : <socket-io,socket-error> ()
  if c-close(socket) == socketError then
    socket-error("socket", get-last-error-string())
  else ()

// Send & recv functions for various types

extern c-send-bytes(socket : socket, bytes : vector<char>) : socket-io int
  c "kk_socket_send_bytes"

pub fun vector-char/send(socket : socket, bytes : vector<char>) : <socket-io,socket-error> int
  val result = c-send-bytes(socket, bytes)
  if result == socketError then
    socket-error("send", get-last-error-string())
  else result

extern c-recv-bytes(socket : socket, num-bytes : int) : socket-io (int,vector<char>)
  c "kk_socket_recv_bytes"

pub fun vector-char/recv(socket : socket, num-bytes : int) : <socket-io,socket-error> vector<char>
  val (res, bytes) = c-recv-bytes(socket, num-bytes)
  if res == socketError then
    socket-error("recv", get-last-error-string())
  else bytes

pub fun char/send(socket : socket, byte : char) : <socket-io,socket-error> int
  val result = c-send-bytes(socket, [byte].vector)
  if result == socketError then
    socket-error("send", get-last-error-string())
  else result

pub fun char/recv(socket : socket) : <socket-io,socket-error> char
  val (res, bytes : vector<char>) = c-recv-bytes(socket, 1)
  if res == socketError then
    socket-error("recv", get-last-error-string())
  else bytes.vector/@index(0)

extern c-send-int(socket : socket, v : int) : socket-io int
  c "kk_socket_send_int"

pub fun int/send(socket : socket, v : int) : <socket-io,socket-error> int
  val result = c-send-int(socket, v)
  if result == socketError then
    socket-error("send", get-last-error-string())
  else result

extern c-recv-int(socket : socket) : socket-io (int, int)
  c "kk_socket_recv_int"

pub fun int/recv(socket : socket) : <socket-io,socket-error> int
  val (res, v) = c-recv-int(socket)
  if res == socketError then
    socket-error("recv", get-last-error-string())
  else v

extern c-send-float64(socket : socket, v : float64) : socket-io int
  c "kk_socket_send_float64"

pub fun float64/send(socket : socket, v : float64) : <socket-io,socket-error> int
  val result = c-send-float64(socket, v)
  if result == socketError then
    socket-error("send", get-last-error-string())
  else result

extern c-recv-float64(socket : socket) : socket-io (int, float64)
  c "kk_socket_recv_float64"

pub fun float64/recv(socket : socket) : <socket-io,socket-error> float64
  val (res, v) = c-recv-float64(socket)
  if res == socketError then
    socket-error("recv", get-last-error-string())
  else v

// End send & recv functions for various types

extern c-shutdown(socket : socket) : socket-io int
  c "kk_socket_shutdown"

pub fun shutdown(socket : socket) : <socket-io,socket-error> ()
  if c-shutdown(socket) == socketError then
    socket-error("shutdown", get-last-error-string())
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
    socket-error("select", get-last-error-string())
  else fds

pub fun is-readable(result : selectResult, socket : socket) : bool
  return result.readable.index-of(fn(s){ s == socket }) != -1

pub fun is-writable(result : selectResult, socket : socket) : bool
  return result.writable.index-of(fn(s){ s == socket }) != -1

pub fun is-errored(result : selectResult, socket : socket) : bool
  return result.errored.index-of(fn(s){ s == socket }) != -1

pub fun raise-errors(result : selectResult) : <socket-io,socket-error> ()
  if !result.errored.is-empty then
    socket-error("raise-errors", get-last-error-string())
  else ()