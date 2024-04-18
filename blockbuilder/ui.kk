module ui

import std/time/duration
import std/time/timestamp
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

pub fun render(ui : gameUi, player-id : int, world : gameWorld, camera : camera, cone-mesh : mesh, material : material) : raylib-io ()
  beginDrawing()

  clearBackground(raywhite)

  beginMode3D(camera.raylib-camera3D)

  // Draw a cone at every other player's position
  world.players.map(fn(p) {
    if p.player/id == player-id then ()
    else
      val transform = matrixTranslate(p.pos.x, p.pos.y, p.pos.z)
      drawMesh(cone-mesh, material, transform)
  })

  val cubePosition = Vector3(-2.0, 2.0, 0.0)
  val cubeWidth = 2.0
  val cubeHeight = 5.0
  val cubeLength = 2.0
  drawCube(cubePosition, cubeWidth, cubeHeight, cubeLength, world.cube-color)

  drawGrid(1000, 1.0)

  endMode3D()

  drawFPS(10, 10)

  endDrawing()

pub fun get-cmds(ui : gameUi, player-id : int, world : gameWorld, prev-camera : camera, camera : camera) : raylib-io list<command>
  val color-switch-command = 
    if isMouseButtonPressed(mouseButtonLeft) then
      match world.cube-color
        Color(230, 41, 55, 255) -> [SetColor(green)]
        Color(0, 228, 48, 255) -> [SetColor(red)]
    else []

  val camera-cmd =
    if prev-camera.position != camera.position then
      [PlayerPosition(player-id, camera.position)]
    else []

  color-switch-command ++ camera-cmd

pub fun get-time(ui : gameUi) : raylib-io duration
  ticks()

pub fun is-key-down(ui : gameUi, key : int) : raylib-io bool
  isKeyDown(key)

pub fun get-mouse-delta(ui : gameUi) : raylib-io vector2
  getMouseDelta()

pub fun get-camera-input(ui : gameUi) : raylib-io cameraMovement
  val mouse-delta = if ui.mouse-captured then
    ui.get-mouse-delta()
  else
    Vector2(0.0, 0.0)

  val move-forward = ui.is-key-down(key-w)
  val move-back = ui.is-key-down(key-s)
  val move-right = ui.is-key-down(key-d)
  val move-left = ui.is-key-down(key-a)
  val move-up = ui.is-key-down(key-space)
  val move-down = ui.is-key-down(key-left-shift)

  CameraMovement(mouse-delta,
                 move-forward,
                 move-back,
                 move-right,
                 move-left,
                 move-up,
                 move-down)