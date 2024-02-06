//================================================================================
// C-imports and DLLs necessary to run/link raylib.
//
// TODO: Can we link different libraries for Linux?

extern import
  c { vcpkg = "raylib"; library = "raylib" }

extern import
  c { file = "raygui.h" }

extern import
  c { syslib = "winmm" }

extern import
  c { syslib = "user32" }

extern import
  c { syslib = "gdi32" }

extern import
  c file "raylib-inline.c"

// Effect to tell Koka that anything can happen in a Raylib function. Should be
// put on everything.
alias raylib-io = io

//================================================================================
// Koka Wrappers for Raylib structs

pub struct raylib-Color
  r : int
  g : int
  b : int
  a : int

pub val raywhite = Raylib-Color( 245, 245, 245, 255 )
pub val white = Raylib-Color( 255, 255, 255, 255 )

pub struct raylib-Rectangle
  x : float32
  y : float32
  width : float32
  height : float32

pub struct raylib-Vector2
  x : float32
  y : float32

pub struct raylib-Texture
  id : int
  width : int
  height : int
  mipmaps : int
  format : int

pub alias raylib-Texture2D = raylib-Texture

// TODO: Maybe make a global struct with int fields for more type safety?

// Enum values for GuiControl
val guiControlDefault : int = 0
val guiControlLabel : int = 1
val guiControlButton : int = 2

// Enum values for GuiControlProperty (GuiControl/DefaultProperty in raygui.h)
val guiControlPropertyTextSize : int = 16

//================================================================================
// Raylib functions

extern raylib-InitWindow( width : int, height : int, window_name : string ) : raylib-io ()
  c "kk_raylib_InitWindow"

pub fun initWindow( width : int, height : int, window_name : string ) : raylib-io ()
  raylib-InitWindow( width, height, window_name )

// TODO: closeWindow

extern raylib-SetTargetFPS( fps : int ) : raylib-io ()
  c "kk_raylib_SetTargetFPS"

pub fun setTargetFPS( fps : int ) : raylib-io ()
  raylib-SetTargetFPS( fps )

extern raylib-WindowShouldClose() : raylib-io bool
  c "kk_raylib_WindowShouldClose"

pub fun windowShouldClose() : raylib-io bool
  raylib-WindowShouldClose()

extern raylib-BeginDrawing() : raylib-io ()
  c "kk_raylib_BeginDrawing"

pub fun beginDrawing() : raylib-io ()
  raylib-BeginDrawing()

extern raylib-EndDrawing() : raylib-io ()
  c "kk_raylib_EndDrawing"

pub fun endDrawing() : raylib-io ()
  raylib-EndDrawing()

// TODO: Colors are currently hard-coded, because raylib takes uint4 structs. Figure out how to deal with that.

extern raylib-ClearBackground( color : raylib-Color ) : raylib-io ()
  c "kk_raylib_ClearBackground"

pub fun clearBackground( color : raylib-Color ) : raylib-io ()
  raylib-ClearBackGround( color )

extern raylib-DrawText( text : string, posX : int, posY : int, fontSize : int ) : raylib-io ()
  c "kk_raylib_DrawText"

pub fun drawText( text : string, posX : int, posY : int, fontSize : int ) : raylib-io ()
  raylib-DrawText( text, posX, posY, fontSize )

extern raylib-measureText( text : string, fontSize : int ) : raylib-io int
  c "kk_raylib_MeasureText"

pub fun measureText( text : string, fontSize : int ) : raylib-io int
  raylib-measureText( text, fontSize )

extern raylib-LoadTexture( fileName : string ) : raylib-io raylib-Texture2D
  c "kk_raylib_LoadTexture"

pub fun loadTexture( fileName : string ) : raylib-io raylib-Texture2D
  raylib-LoadTexture( fileName )

// TODO: unloadTexture

extern raylib-DrawTexture( texture : raylib-Texture2D, posX : int, posY : int, tint : raylib-Color ) : raylib-io ()
  c "kk_raylib_DrawTexture"

pub fun drawTexture( texture : raylib-Texture2D, posX : int, posY : int, tint : raylib-Color ) : raylib-io ()
  raylib-DrawTexture( texture, posX, posY, tint )

extern raylib-DrawTextureEx( texture : raylib-Texture2D, position : raylib-Vector2, rotation : float32, scale : float32, tint : raylib-Color ) : raylib-io ()
  c "kk_raylib_DrawTextureEx"

pub fun drawTextureEx( texture : raylib-Texture2D, position : raylib-Vector2, rotation : float32, scale : float32, tint : raylib-Color ) : raylib-io ()
  raylib-DrawTextureEx( texture, position, rotation, scale, tint )

//================================================================================
// Raygui functions

extern raylib-GuiSetStyle( rl_control : int, property : int, value : int ) : raylib-io ()
  c "kk_raylib_GuiSetStyle"

pub fun guiSetStyle( rl_control : int, property : int, value : int ) : raylib-io ()
  raylib-GuiSetStyle( rl_control, property, value )

extern raylib-GuiButton( bounds : raylib-Rectangle, text : string ) : raylib-io bool
  c "kk_raylib_GuiButton"

pub fun guiButton( bounds : raylib-Rectangle, text : string ) : raylib-io bool
  raylib-GuiButton( bounds, text )