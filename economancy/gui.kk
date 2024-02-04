import std/num/float64

import raylib/raylib

import game

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
  
pub fun init-gui() : raylib-io guiState
  initWindow( windowWidth, windowHeight, "Economancy")
  guiSetStyle( guiControlDefault, guiControlPropertyTextSize, 16 * 4 )
  setTargetFPS( 60 )

  GuiState( MainMenu )

fun start-view() : raylib-io maybe<guiCommand>
  val buttonWidth : float64 = windowWidth.float64 / 4.0
  val buttonHeight : float64 = windowHeight.float64 / 4.0
  val buttonXPos : float64 = windowWidth.float64 / 2.0 - buttonWidth / 2.0
  val buttonYPos : float64 = windowHeight.float64 / 2.0 - buttonHeight / 2.0
  val buttonRect = Raylib-Rectangle( buttonXPos.float32, buttonYPos.float32, buttonWidth.float32, buttonHeight.float32 )

  val start-clicked = guiButton( buttonRect, "Start" )
  if start-clicked then Just( Start )
  else Nothing

fun income-view() : raylib-io maybe<guiCommand>
  drawText("INCOME", 100, 100, 100 )
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
      gui/Playing -> income-view()

    endDrawing()

    match gui-cmd
      Just( Start ) -> GuiUpdateResult( GuiState( Playing ), Nothing )
      _ -> GuiUpdateResult( gui-state, gui-cmd )
