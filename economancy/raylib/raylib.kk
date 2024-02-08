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

pub struct color
  r : int
  g : int
  b : int
  a : int

pub val lightgray = Color(200, 200, 200, 255)
pub val gray = Color(130, 130, 130, 255)
pub val darkgray = Color(80, 80, 80, 255)
pub val yellow = Color(253, 249, 0, 255)
pub val gold = Color(255, 203, 0, 255)
pub val orange = Color(255, 161, 0, 255)
pub val pink = Color(255, 109, 194, 255)
pub val red = Color(230, 41, 55, 255)
pub val maroon = Color(190, 33, 55, 255)
pub val green = Color(0, 228, 48, 255)
pub val lime = Color(0, 158, 47, 255)
pub val darkgreen = Color(0, 117, 44, 255)
pub val skyblue = Color(102, 191, 255, 255)
pub val blue = Color(0, 121, 241, 255)
pub val darkblue = Color(0, 82, 172, 255)
pub val purple = Color(200, 122, 255, 255)
pub val violet = Color(135, 60, 190, 255)
pub val darkpurple = Color(112, 31, 126, 255)
pub val beige = Color(211, 176, 131, 255)
pub val brown = Color(127, 106, 79, 255)
pub val darkbrown = Color(76, 63, 47, 255)
pub val white = Color(255, 255, 255, 255)
pub val black = Color(0, 0, 0, 255)
pub val blank = Color(0, 0, 0, 0)
pub val magenta = Color(255, 0, 255, 255)
pub val raywhite = Color(245, 245, 245, 255)

pub struct rectangle
  x : float32
  y : float32
  width : float32
  height : float32

pub struct vector2
  x : float32
  y : float32

pub struct texture
  id : int
  width : int
  height : int
  mipmaps : int
  format : int

pub alias texture2D = texture

pub val mouseButtonLeft : int = 0
pub val mouseButtonRight : int = 1
pub val mouseButtonMiddle : int = 2
pub val mouseButtonSide : int = 3
pub val mouseButtonExtra : int = 4
pub val mouseButtonForward : int = 5
pub val mouseButtonBack : int = 6

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

extern raylib-ClearBackground( color : color ) : raylib-io ()
  c "kk_raylib_ClearBackground"

pub fun clearBackground( color : color ) : raylib-io ()
  raylib-ClearBackGround( color )

extern raylib-DrawText( text : string, posX : int, posY : int, fontSize : int, color : color ) : raylib-io ()
  c "kk_raylib_DrawText"

pub fun drawText( text : string, posX : int, posY : int, fontSize : int, color : color ) : raylib-io ()
  raylib-DrawText( text, posX, posY, fontSize, color )

extern raylib-measureText( text : string, fontSize : int ) : raylib-io int
  c "kk_raylib_MeasureText"

pub fun measureText( text : string, fontSize : int ) : raylib-io int
  raylib-measureText( text, fontSize )

extern raylib-LoadTexture( fileName : string ) : raylib-io texture2D
  c "kk_raylib_LoadTexture"

pub fun loadTexture( fileName : string ) : raylib-io texture2D
  raylib-LoadTexture( fileName )

// TODO: unloadTexture

extern raylib-DrawTexture( texture : texture2D, posX : int, posY : int, tint : color ) : raylib-io ()
  c "kk_raylib_DrawTexture"

pub fun drawTexture( texture : texture2D, posX : int, posY : int, tint : color ) : raylib-io ()
  raylib-DrawTexture( texture, posX, posY, tint )

extern raylib-DrawTextureEx( texture : texture2D, position : vector2, rotation : float32, scale : float32, tint : color ) : raylib-io ()
  c "kk_raylib_DrawTextureEx"

pub fun drawTextureEx( texture : texture2D, position : vector2, rotation : float32, scale : float32, tint : color ) : raylib-io ()
  raylib-DrawTextureEx( texture, position, rotation, scale, tint )

extern raylib-IsMouseButtonPressed( button : int ) : raylib-io bool
  c "kk_raylib_IsMouseButtonPressed"

pub fun isMouseButtonPressed( button : int ) : raylib-io bool
  raylib-IsMouseButtonPressed( button )

extern raylib-GetMousePosition() : raylib-io vector2
  c "kk_raylib_GetMousePosition"

pub fun getMousePosition() : raylib-io vector2
  raylib-GetMousePosition()

//================================================================================
// Raygui functions

extern raylib-GuiSetStyle( rl_control : int, property : int, value : int ) : raylib-io ()
  c "kk_raylib_GuiSetStyle"

pub fun guiSetStyle( rl_control : int, property : int, value : int ) : raylib-io ()
  raylib-GuiSetStyle( rl_control, property, value )

extern raylib-GuiButton( bounds : rectangle, text : string ) : raylib-io bool
  c "kk_raylib_GuiButton"

pub fun guiButton( bounds : rectangle, text : string ) : raylib-io bool
  raylib-GuiButton( bounds, text )