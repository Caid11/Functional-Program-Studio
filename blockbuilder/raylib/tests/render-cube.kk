module raylib/tests/render-cube

import raylib/raylib

fun main()
  val screen-width = 800
  val screen-height = 450

  initWindow(screen-width, screen-height, "Render cube")
  setTargetFPS(60)

  val position = Vector3(0.0, 10.0, 10.0)
  val target = Vector3(0.0, 0.0, 0.0)
  val up = Vector3(0.0, 1.0, 0.0)
  val fov = 45.0
  val projection = cameraPerspective
  val camera = Camera3D(position, target, up, fov, projection)

  fun main-r()
    if windowShouldClose() then ()
    else
      beginDrawing()

      clearBackground(raywhite)

      beginMode3D(camera)

      val cubePosition = Vector3(-2.0, 2.0, 0.0)
      val cubeWidth = 2.0
      val cubeHeight = 5.0
      val cubeLength = 2.0
      drawCube(cubePosition, cubeWidth, cubeHeight, cubeLength, red)

      endMode3D()

      drawFPS(10, 10)

      endDrawing()
      main-r()
  
  main-r()
  closeWindow()