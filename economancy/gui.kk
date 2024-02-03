import std/num/float64
import raylib/raylib

pub type guiCommand
  Start
  Quit

pub type guiMode
  MainMenu
  Playing

val windowWidth = 1024
val windowHeight = 768

pub struct guiState
  mode : guiMode
  
pub fun init-game() : raylib-io guiState
  initWindow( windowWidth, windowHeight, "Economancy")
  guiSetStyle( guiControlDefault, guiControlPropertyTextSize, 16 * 4 )
  setTargetFPS( 60 )

  GuiState( MainMenu )

pub fun update( g : guiState ) : raylib-io maybe<guiCommand>
  if windowShouldClose() then Just( Quit )
  else
    beginDrawing()

    val buttonWidth : float64 = windowWidth.float64 / 4.0
    val buttonHeight : float64 = windowHeight.float64 / 4.0
    val buttonXPos : float64 = windowWidth.float64 / 2.0 - buttonWidth / 2.0
    val buttonYPos : float64 = windowHeight.float64 / 2.0 - buttonHeight / 2.0
    val buttonRect = Raylib-Rectangle( buttonXPos.float32, buttonYPos.float32, buttonWidth.float32, buttonHeight.float32 )

    val start-clicked = guiButton( buttonRect, "Start" )

    endDrawing()

    if start-clicked then Just( Start )
    else Nothing
