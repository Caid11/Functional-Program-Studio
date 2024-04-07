import std/num/ddouble
import std/num/float64
import std/os/env
import std/time/duration

import raylib/raylib

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

  val args = parse-args(get-args())
  match args.connect
    Nothing -> println("nothing")
    Just(addr) -> println(addr)

  // Game state
  val world = GameWorld()

  // Either connect to or start server

  val server = match args.connect
    Nothing -> LocalServer
    Just(addr) -> RemoteServer(addr)

  // Initialize renderer

  val ui = GameUi()
  ui.init()

  with finally{ ui.destroy() }

  // Game loop

  fun loop(ui: gameUi, world : gameWorld, last-time : duration)
    if ui.exit() then ()
    else
      // Collect/broadcast commands

      val local-cmds = ui.get-cmds()
      val server-cmds = server.get-cmds()

      server.submit-cmds(local-cmds)

      server.broadcast-cmds

      // Update world

      val curr-time = ui.get-time()
      val elapsed = curr-time - last-time

      val cmds-to-process = local-cmds ++ server-cmds

      fun update-world(world : gameWorld, elapsed : duration)
        if elapsed <= ms-per-update then world
        else
          val new-world = world.tick(cmds-to-process)
          val new-elapsed = elapsed - ms-per-update
          update-world(new-world, new-elapsed)

      val new-world = update-world(world, elapsed)

      // Render

      ui.render(new-world)
  
      loop(ui, new-world, curr-time)

  loop(ui, world, ui.get-time())