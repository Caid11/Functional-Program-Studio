import std/num/float64

//================================================================================
// C-imports and DLLs necessary to run/link raylib.
//
// TODO: Can we link different libraries for Linux?

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

pub val key-null            = 0        // No key
pub val key-apostrophe      = 39       // Key: '
pub val key-comma           = 44       // Key: ,
pub val key-minus           = 45       // Key: -
pub val key-period          = 46       // Key: .
pub val key-slash           = 47       // Key: /
pub val key-zero            = 48       // Key: 0
pub val key-one             = 49       // Key: 1
pub val key-two             = 50       // Key: 2
pub val key-three           = 51       // Key: 3
pub val key-four            = 52       // Key: 4
pub val key-five            = 53       // Key: 5
pub val key-six             = 54       // Key: 6
pub val key-seven           = 55       // Key: 7
pub val key-eight           = 56       // Key: 8
pub val key-nine            = 57       // Key: 9
pub val key-semicolon       = 59       // Key: ;
pub val key-equal           = 61       // Key: =
pub val key-a               = 65       // Key: A | a
pub val key-b               = 66       // Key: B | b
pub val key-c               = 67       // Key: C | c
pub val key-d               = 68       // Key: D | d
pub val key-e               = 69       // Key: E | e
pub val key-f               = 70       // Key: F | f
pub val key-g               = 71       // Key: G | g
pub val key-h               = 72       // Key: H | h
pub val key-i               = 73       // Key: I | i
pub val key-j               = 74       // Key: J | j
pub val key-k               = 75       // Key: K | k
pub val key-l               = 76       // Key: L | l
pub val key-m               = 77       // Key: M | m
pub val key-n               = 78       // Key: N | n
pub val key-o               = 79       // Key: O | o
pub val key-p               = 80       // Key: P | p
pub val key-q               = 81       // Key: Q | q
pub val key-r               = 82       // Key: R | r
pub val key-s               = 83       // Key: S | s
pub val key-t               = 84       // Key: T | t
pub val key-u               = 85       // Key: U | u
pub val key-v               = 86       // Key: V | v
pub val key-w               = 87       // Key: W | w
pub val key-x               = 88       // Key: X | x
pub val key-y               = 89       // Key: Y | y
pub val key-z               = 90       // Key: Z | z
pub val key-left-bracket    = 91       // Key: [
pub val key-backslash       = 92       // Key: '\'
pub val key-right-bracket   = 93       // Key: ]
pub val key-grave           = 96       // Key: `
// Function keys
pub val key-space           = 32       // Key: Space
pub val key-escape          = 256      // Key: Esc
pub val key-enter           = 257      // Key: Enter
pub val key-tab             = 258      // Key: Tab
pub val key-backspace       = 259      // Key: Backspace
pub val key-insert          = 260      // Key: Ins
pub val key-delete          = 261      // Key: Del
pub val key-right           = 262      // Key: Cursor right
pub val key-left            = 263      // Key: Cursor left
pub val key-down            = 264      // Key: Cursor down
pub val key-up              = 265      // Key: Cursor up
pub val key-page-up         = 266      // Key: Page up
pub val key-page-down       = 267      // Key: Page down
pub val key-home            = 268      // Key: Home
pub val key-end             = 269      // Key: End
pub val key-caps-lock       = 280      // Key: Caps lock
pub val key-scroll-lock     = 281      // Key: Scroll down
pub val key-num-lock        = 282      // Key: Num lock
pub val key-print-screen    = 283      // Key: Print screen
pub val key-pause           = 284      // Key: Pause
pub val key-f1              = 290      // Key: F1
pub val key-f2              = 291      // Key: F2
pub val key-f3              = 292      // Key: F3
pub val key-f4              = 293      // Key: F4
pub val key-f5              = 294      // Key: F5
pub val key-f6              = 295      // Key: F6
pub val key-f7              = 296      // Key: F7
pub val key-f8              = 297      // Key: F8
pub val key-f9              = 298      // Key: F9
pub val key-f10             = 299      // Key: F10
pub val key-f11             = 300      // Key: F11
pub val key-f12             = 301      // Key: F12
pub val key-left-shift      = 340      // Key: Shift left
pub val key-left-control    = 341      // Key: Control left
pub val key-left-alt        = 342      // Key: Alt left
pub val key-left-super      = 343      // Key: Super left
pub val key-right-shift     = 344      // Key: Shift right
pub val key-right-control   = 345      // Key: Control right
pub val key-right-alt       = 346      // Key: Alt right
pub val key-right-super     = 347      // Key: Super right
pub val key-kb-menu         = 348      // Key: KB menu
// Keypad keys
pub val key-kp0            = 320      // Key: Keypad 0
pub val key-kp1            = 321      // Key: Keypad 1
pub val key-kp2            = 322      // Key: Keypad 2
pub val key-kp3            = 323      // Key: Keypad 3
pub val key-kp4            = 324      // Key: Keypad 4
pub val key-kp5            = 325      // Key: Keypad 5
pub val key-kp6            = 326      // Key: Keypad 6
pub val key-kp7            = 327      // Key: Keypad 7
pub val key-kp8            = 328      // Key: Keypad 8
pub val key-kp9            = 329      // Key: Keypad 9
pub val key-kp-decimal      = 330      // Key: Keypad .
pub val key-kp-divide       = 331      // Key: Keypad /
pub val key-kp-multiply     = 332      // Key: Keypad *
pub val key-kp-subtract     = 333      // Key: Keypad -
pub val key-kp-add          = 334      // Key: Keypad +
pub val key-kp-enter        = 335      // Key: Keypad Enter
pub val key-kp-equal        = 336      // Key: Keypad =

// TODO: Switch float32's to float64's

pub struct rectangle
  x : float32
  y : float32
  width : float32
  height : float32

pub struct vector2
  x : float64
  y : float64

pub struct vector3
  x : float64
  y : float64
  z : float64

pub struct matrix
  m0 : float64
  m1 : float64
  m2 : float64
  m3 : float64
  m4 : float64
  m5 : float64
  m6 : float64
  m7 : float64
  m8 : float64
  m9 : float64
  m10 : float64
  m11 : float64
  m12 : float64
  m13 : float64
  m14 : float64
  m15 : float64

pub struct texture
  id : int
  width : int
  height : int
  mipmaps : int
  format : int

pub struct mesh
  vertex-count : int
  triangle-count : int

  vertices : vector<float64>
  texcoords : vector<float64>
  texcoords2 : vector<float64>
  normals : vector<float64>
  tangents : vector<float64>
  colors : vector<char>
  indices : vector<int32> // These are actually shorts

  // TODO: animations not implemented

  vao-id : int
  vbo-id : vector<int>

pub struct shader
  id : int
  locs : vector<int>

pub struct materialMap
  texture : texture
  color : color
  value : float64

pub struct material
  shader : shader
  maps : vector<materialMap>
  params : vector<float64>

// pub struct model
//   transform : matrix
// 
//   mesh-count : int
//   material-count : int
//   mesh : vector<mesh>
//   material : vector<material>
//   mesh-materal : vector<int>
// 
//   // TODO: Animations not implemented

pub val cameraPerspective : int = 0
pub val cameraOrthographic : int = 1

pub struct camera3D
  position : vector3
  target : vector3
  up : vector3
  fovy : float64
  projection : int

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
// Koka convenience functions

pub fun color/show(c : color) : string
  [c.r, c.g, c.b, c.a].map(show).join(" ")

pub fun vector3/show(v : vector3) : string
  "[" ++ [v.x, v.y, v.z].map(fn(x){x.show}).join(" ") ++ "]"

pub fun color/(==)(x : color, y : color) : bool 
  [
    x.r == y.r,
    x.g == y.g,
    x.b == y.b,
    x.a == y.a
  ].all(fn(x){ x })

//================================================================================
// Raylib functions

extern initWindow(width : int, height : int, window_name : string) : raylib-io ()
  c "kk_raylib_InitWindow"

extern closeWindow() : raylib-io ()
  c "kk_raylib_CloseWindow"

extern setTargetFPS(fps : int) : raylib-io ()
  c "kk_raylib_SetTargetFPS"

extern disableCursor() : raylib-io ()
  c "kk_raylib_DisableCursor"

extern enableCursor() : raylib-io ()
  c "kk_raylib_EnableCursor"

extern isCursorOnScreen() : raylib-io bool
  c "kk_raylib_IsCursorOnScreen"

extern windowShouldClose() : raylib-io bool
  c "kk_raylib_WindowShouldClose"

extern beginDrawing() : raylib-io ()
  c "kk_raylib_BeginDrawing"

extern endDrawing() : raylib-io ()
  c "kk_raylib_EndDrawing"

extern clearBackground(color : color) : raylib-io ()
  c "kk_raylib_ClearBackground"

extern drawFPS(posX : int, posY : int) : raylib-io ()
  c "kk_raylib_DrawFPS"

extern drawText(text : string, posX : int, posY : int, fontSize : int, color : color) : raylib-io ()
  c "kk_raylib_DrawText"

extern measureText(text : string, fontSize : int) : raylib-io int
  c "kk_raylib_MeasureText"

extern drawCube(position : vector3, width : float64, height : float64, length : float64, color : color ) : raylib-io ()
  c "kk_raylib_DrawCube"

extern drawGrid(slices : int, spaceing : float64) : raylib-io ()
  c "kk_raylib_DrawGrid"

extern loadTexture(fileName : string) : raylib-io texture2D
  c "kk_raylib_LoadTexture"

// TODO: unloadTexture

extern drawTexture(texture : texture2D, posX : int, posY : int, tint : color) : raylib-io ()
  c "kk_raylib_DrawTexture"

extern drawTextureEx(texture : texture2D, position : vector2, rotation : float32, scale : float32, tint : color) : raylib-io ()
  c "kk_raylib_DrawTextureEx"

extern genMeshCone(radius : float64, height: float64, slices : int) : raylib-io mesh
  c "kk_raylib_GenMeshCone"

extern loadMaterialDefault() : raylib-io material
  c "kk_raylib_LoadMaterialDefault"

extern isKeyPressed(key : int) : raylib-io bool
  c "kk_raylib_IsKeyPressed"

extern isKeyDown(key : int) : raylib-io bool
  c "kk_raylib_IsKeyDown"

extern setExitKey(key : int) : raylib-io ()
  c "kk_raylib_SetExitKey"

extern isMouseButtonPressed(button : int) : raylib-io bool
  c "kk_raylib_IsMouseButtonPressed"

extern getMousePosition() : raylib-io vector2
  c "kk_raylib_GetMousePosition"

extern getMouseDelta() : raylib-io vector2
  c "kk_raylib_GetMouseDelta"

extern beginMode3D(camera : camera3D) : raylib-io ()
  c "kk_raylib_BeginMode3D"

extern endMode3D() : raylib-io ()
  c "kk_raylib_EndMode3D"

//================================================================================
// Raygui functions

extern guiSetStyle(rl_control : int, property : int, value : int) : raylib-io ()
  c "kk_raylib_GuiSetStyle"

extern guiButton(bounds : rectangle, text : string) : raylib-io bool
  c "kk_raylib_GuiButton"

extern guiTextBox(bounds : rectangle, text : string, buffer-size : int,  edit-mode : bool) : raylib-io (string, bool)
  c "kk_raylib_GuiTextBox"