import std/num/float64

import raylib/raylib

import game

pub type guiCommand
  Start
  Quit

pub type guiMode
  MainMenu
  Playing

val windowWidth = 1920
val windowHeight = 1080

pub struct guiState
  mode : guiMode
  card : raylib-Texture2D
  
pub fun init-gui() : raylib-io guiState
  initWindow( windowWidth, windowHeight, "Economancy")
  guiSetStyle( guiControlDefault, guiControlPropertyTextSize, 16 * 4 )
  setTargetFPS( 60 )
  val card = loadTexture( "assets/sorcerers_stipend.png" )

  GuiState( MainMenu, card )

fun draw-phase( game-phase : phase ) : raylib-io ()
  drawText( game-phase.str, 25, 25, 44 )

fun draw-day( game-day : day ) : raylib-io ()
  val day-text = "DAY " ++ game-day.str
  val text-width = raylib-MeasureText( day-text, 44 )
  drawText( day-text, windowWidth - text-width - 25, 25, 44 )

fun start-view() : raylib-io maybe<guiCommand>
  val buttonWidth : float64 = windowWidth.float64 / 4.0
  val buttonHeight : float64 = windowHeight.float64 / 4.0
  val buttonXPos : float64 = windowWidth.float64 / 2.0 - buttonWidth / 2.0
  val buttonYPos : float64 = windowHeight.float64 / 2.0 - buttonHeight / 2.0
  val buttonRect = Raylib-Rectangle( buttonXPos.float32, buttonYPos.float32, buttonWidth.float32, buttonHeight.float32 )

  val start-clicked = guiButton( buttonRect, "Start" )
  if start-clicked then Just( Start )
  else Nothing

fun income-view( gui-state : guiState, game-state : gameState ) : raylib-io maybe<guiCommand>
  draw-phase( game-state.phase )
  draw-day( game-state.day )
  drawTexture( gui-state.card, 100, 300, white )
  Nothing

pub struct guiUpdateResult
  gui-state : guiState
  gui-cmd : maybe<guiCommand>

pub fun update( gui-state : guiState, game-state : gameState ) : raylib-io guiUpdateResult
  if windowShouldClose() then GuiUpdateResult( gui-state, Just( Quit ) )
  else
    clearBackground( raywhite )
    beginDrawing()

    val gui-cmd = match gui-state.mode
      gui/MainMenu -> start-view()
      gui/Playing -> income-view( gui-state, game-state )

    endDrawing()

    match gui-cmd
      Just( Start ) -> GuiUpdateResult( GuiState( Playing, gui-state.card ), Nothing )
      _ -> GuiUpdateResult( gui-state, gui-cmd )
