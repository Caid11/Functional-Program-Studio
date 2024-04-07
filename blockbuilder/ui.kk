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
  val position = Vector3(0.0, 10.0, 10.0)
  val target = Vector3(0.0, 0.0, 0.0)
  val up = Vector3(0.0, 1.0, 0.0)
  val fov = 45.0
  val projection = cameraPerspective
  val camera = Camera3D(position, target, up, fov, projection)

  beginDrawing()

  clearBackground(raywhite)

  beginMode3D(camera)

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