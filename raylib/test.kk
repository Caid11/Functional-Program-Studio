import raylib/raylib

fun main()
  initWindow( 800, 450, "Raylib - Koka")
  setTargetFPS( 60 )

  fun window-loop()
    if windowShouldClose() then ()
    else
      beginDrawing()

      clearBackground()
      drawText( "Hello from Koka+Raylib!", 190, 200, 40 )

      endDrawing()

      window-loop()

  window-loop()