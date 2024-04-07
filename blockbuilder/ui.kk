module ui

import std/time/duration
import std/time/timer

import raylib/raylib

import commands
import world

pub struct gameUi
  bleh : int = 0

val window-width = 1920
val window-height = 1080

val window-title = "BlockBuilder"

pub fun init(ui : gameUi) : raylib-io ()
  initWindow(window-width, window-height, window-title)
  setTargetFPS(60)

pub fun destroy(ui : gameUi) : raylib-io ()
  closeWindow()

pub fun exit(ui : gameUi) : raylib-io bool
  windowShouldClose()

pub fun render(ui : gameUi, world : gameWorld) : raylib-io ()
  beginDrawing()

  clearBackground(raywhite)
  drawText("Hello from Raylib!", 190, 200, 20, lightgray)

  endDrawing()

pub fun get-cmds(ui : gameUi) : raylib-io list<command>
  // TODO
  []

pub fun get-time(ui : gameUi) : raylib-io duration
  ticks()