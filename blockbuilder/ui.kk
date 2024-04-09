module ui

import std/time/duration
import std/time/timer

import raylib/raylib

import camera
import commands
import world

pub struct gameUi
  mouse-captured : bool = True

val window-width = 1920
val window-height = 1080

val window-title = "BlockBuilder"

pub fun init(ui : gameUi) : raylib-io ()
  initWindow(window-width, window-height, window-title)
  setTargetFPS(60)
  ui.capture-cursor()

fun capture-cursor(ui : gameUi) : raylib-io ()
  disableCursor()

fun release-cursor(ui : gameUi) : raylib-io ()
  enableCursor()

pub fun capture-release-mouse(ui : gameUi) : raylib-io gameUi
  if ui.mouse-captured then
    if isKeyPressed(key-q) then
      ui.release-cursor()
      ui(mouse-captured = False)
    else ui
  else if isMouseButtonPressed(mouseButtonLeft) && isCursorOnScreen() then
    ui.capture-cursor()
    ui(mouse-captured = True)
  else ui

pub fun destroy(ui : gameUi) : raylib-io ()
  closeWindow()

pub fun exit(ui : gameUi) : raylib-io bool
  windowShouldClose()

pub fun render(ui : gameUi, world : gameWorld, camera : camera) : raylib-io ()
  beginDrawing()

  clearBackground(raywhite)

  beginMode3D(camera.raylib-camera3D)

  val cubePosition = Vector3(-2.0, 2.0, 0.0)
  val cubeWidth = 2.0
  val cubeHeight = 5.0
  val cubeLength = 2.0
  drawCube(cubePosition, cubeWidth, cubeHeight, cubeLength, world.color)

  endMode3D()

  drawFPS(10, 10)

  endDrawing()

pub fun get-cmds(ui : gameUi) : raylib-io list<command>
  if isMouseButtonPressed(mouseButtonLeft) then
    [SwitchColor]
  else []

pub fun get-time(ui : gameUi) : raylib-io duration
  ticks()

pub fun is-key-down(ui : gameUi, key : int) : raylib-io bool
  isKeyDown(key)

pub fun get-mouse-delta(ui : gameUi) : raylib-io vector2
  getMouseDelta()