module raylib/tests/create-window

import raylib/raylib

fun main()
  val screen-width = 800
  val screen-height = 450

  initWindow(screen-width, screen-height, "Hello Raylib")
  setTargetFPS(60)

  fun main-r()
    if windowShouldClose() then ()
    else
      beginDrawing()

      clearBackground(raywhite)
      drawText("Hello from Raylib!", 190, 200, 20, lightgray)

      endDrawing()
      main-r()
  
  main-r()
  closeWindow()