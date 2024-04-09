import std/num/ddouble
import std/num/float64
import std/os/env
import std/time/duration
import std/time/timer

import raylib/raylib
import socket/socket

import camera
import lmath
import server
import ui
import world

struct args
  connect : maybe<string> = Nothing

effect parseError
  ctl show-help() : a
  ctl parse-error(msg: string) : a

fun parse-args(args : list<string>, curr-args : args = Args())
  match args
    Nil -> curr-args
    Cons(x, xs) ->
      match x
        "-h" -> show-help()
        "--help" -> show-help()
        "--connect" ->
          match xs
            Nil -> parse-error("--connect given with no address")
            Cons(y, ys) ->
              if y.vector[0] == '-' then
                parse-error("--connect given with no address")
              else
                parse-args(ys, curr-args(connect = Just(y)))
        _ -> show-help()

fun print-usage()
  println("bb [--connect address]")

fun main()
  // Parse arguments

  with handler
    final ctl parse-error(msg) println(msg)
    final ctl show-help() print-usage()

  with handler
    final ctl socket-error(msg) println(msg)

  val args = parse-args(get-args())

  // Make sure socket lib is initialized
  socket-init()
  with finally{ socket-shutdown() }

  // Game state
  val world = GameWorld()

  // Local state
  val camera = Camera(Vector3(0.0, 10.0, 10.0))

  // Either connect to or start server

  val server = match args.connect
    Nothing -> create-local-server()
    Just(addr) -> create-remote-server(addr)

  // Initialize renderer

  val ui = GameUi()
  ui.init()

  with finally{ ui.destroy() }

  // Game loop

  fun loop(server : server, ui: gameUi, world : gameWorld, camera : camera)
    if ui.exit() then ()
    else
      val updated-camera = if ui.is-key-down(key-w) then
        camera.move-forward()
      else camera

      val local-cmds = ui.get-cmds()

      val server-with-conns = server.update-conns()
      val server-with-local = server-with-conns.submit-cmds(local-cmds)
      val server-with-remote = server-with-local.poll-cmds()

      val (updated-world, updated-server) = server-with-remote.get-updated(world)

      updated-server.broadcast-world(world, updated-world)

      // Render

      ui.render(updated-world, updated-camera)
  
      loop(updated-server, ui, updated-world, updated-camera)

  loop(server, ui, world, camera)