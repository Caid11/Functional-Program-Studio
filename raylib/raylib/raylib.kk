extern import
  c { vcpkg = "raylib"; library = "raylib" }

extern import
  c { syslib = "winmm" }

extern import
  c { syslib = "user32" }

extern import
  c { syslib = "gdi32" }

extern import
  c file "raylib-inline.c"

extern raylib-InitWindow( width : int, height : int, window_name : string ) : ()
  c "kk_raylib_InitWindow"

pub fun initWindow( width : int, height : int, window_name : string ) : ()
  raylib-InitWindow( width, height, window_name )

extern raylib-SetTargetFPS( fps : int ) : ()
  c "kk_raylib_SetTargetFPS"

pub fun setTargetFPS( fps : int ) : ()
  raylib-SetTargetFPS( fps )

extern raylib-WindowShouldClose() : bool
  c "kk_raylib_WindowShouldClose"

pub fun windowShouldClose() : bool
  raylib-WindowShouldClose()

extern raylib-BeginDrawing() : ()
  c "kk_raylib_BeginDrawing"

pub fun beginDrawing() : ()
  raylib-BeginDrawing()

extern raylib-EndDrawing() : ()
  c "kk_raylib_EndDrawing"

pub fun endDrawing() : ()
  raylib-EndDrawing()

// TODO: Colors are currently hard-coded, because raylib takes uint4 structs. Figure out how to deal with that.

extern raylib-ClearBackground() : ()
  c "kk_raylib_ClearBackground"

pub fun clearBackground() : ()
  raylib-ClearBackGround()

extern raylib-DrawText( text : string, posX : int, posY : int, fontSize : int ) : ()
  c "kk_raylib_DrawText"

pub fun drawText( text : string, posX : int, posY : int, fontSize : int ) : ()
  raylib-DrawText( text, posX, posY, fontSize )