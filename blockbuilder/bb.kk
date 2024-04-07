import std/num/ddouble
import std/num/float64
import std/os/env
import std/time/duration
import std/time/timer

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
    Nothing -> LocalServer(ticks(), [])
    Just(addr) -> RemoteServer(addr)

  // Initialize renderer

  val ui = GameUi()
  ui.init()

  with finally{ ui.destroy() }

  // Game loop

  fun loop(ui: gameUi, world : gameWorld)
    if ui.exit() then ()
    else
      val local-cmds = ui.get-cmds()

      val server-with-local = server.submit-cmds(local-cmds)
      val server-with-remote = server-with-local.poll-cmds()

      val (updated-world, updated-server) = server-with-remote.get-updated(world)

      // Render

      ui.render(updated-world)
  
      loop(ui, updated-world)

  loop(ui, world)