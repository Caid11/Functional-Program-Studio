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
  val phase-text-width = raylib-MeasureText( game-phase.str, 44 )
  val phase-x = windowWidth - phase-text-width - 25
  drawText( game-phase.str, phase-x, 25, 44 )

fun draw-day( game-day : day ) : raylib-io ()
  val day-text = "DAY " ++ game-day.str
  drawText( day-text, 25, 25, 44 )

fun center( container-width : int, object-width : int ) : int
  container-width / 2 - object-width / 2

fun get-player-coords( player-idx : int, container-width : int, container-height )
  val center-horizontal = center(windowWidth, container-width)
  val center-vertical = center(windowHeight, container-height)

  match player-idx
    0 -> (center-horizontal, windowHeight - container-height)
    1 -> (windowWidth - container-width, center-vertical)
    2 -> (center-horizontal, 0)
    3 -> (0, center-vertical)

fun draw-player( gui-state : guiState, player-idx : int, player : player )
  val container-width = windowWidth / 5
  val container-height = windowHeight / 4
  val (container-x, container-y) = get-player-coords( player-idx, container-width, container-height )

  // Name
  val name-font-size = 36
  val name-x = center(container-width, raylib-MeasureText( player.name, name-font-size ))
  raylib-DrawText( player.name, container-x + name-x, container-y, name-font-size )

  // Cards
  val card-width = container-width / 4
  val card-scale = float32(card-width.float64 / gui-state.card.width.float64)
  val card-height = int(gui-state.card.height.float64 * card-scale.float64)

  // TODO: Hard-coded to 1 card
  val cardPos = Raylib-Vector2(container-x.float32, float32(name-font-size + container-y))
  drawTextureEx(gui-state.card, cardPos, float32(0.0), card-scale, white)

  // Coins
  raylib-DrawText( "Coins: " ++ player.coins.show, container-x, container-y + name-font-size + card-height, name-font-size )

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

  val player-idxs = list(0, game-state.players.length - 1 )

  val draw-with-state = fn((idx, player)){ draw-player(gui-state, idx, player) }
  map( zip( player-idxs, game-state.players ), draw-with-state )
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
