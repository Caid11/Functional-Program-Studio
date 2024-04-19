import std/num/float64
import std/num/ddouble
import std/os/env
// import std/time/duration

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
    final ctl socket-error(call, msg) println(call ++ " " ++ msg)

  val args = parse-args(get-args())

  // Make sure socket lib is initialized
  socket-init()
  with finally{ socket-shutdown() }

  // Local state
  val camera = Camera(Vector3(0.0, 10.0, 10.0), 0.0, 0.0)

  // Either connect to or start server
  with handler
    final ctl server-error(msg) println(msg)

  val (server, player-id) = match args.connect
    Nothing -> create-local-server()
    Just(addr) -> create-remote-server(addr)

  // Initialize renderer

  val ui = GameUi()
  ui.init()

  with finally{ ui.destroy() }

  val cone-mesh = genMeshCone(1.0, 1.0, 5)
  val default-material = loadMaterialDefault()

  // Game loop

  fun loop(prev-server : server, prev-ui: gameUi, prev-camera : camera)
    if prev-ui.exit() then ()
    else
      val ui = prev-ui.capture-release-mouse()

      val camera-input = ui.get-camera-input()
      val camera = prev-camera.update(camera-input)

      val local-cmds = ui.get-cmds(player-id, prev-server.world, prev-camera, camera)

      val server = prev-server
        .update-conns()
        .recv-cmds()
        .send-cmds(local-cmds)
        .apply-cmds()

      // Render
      ui.render(player-id, server.world, camera, cone-mesh, default-material)
  
      loop(server, ui, camera)

  loop(server, ui, camera)