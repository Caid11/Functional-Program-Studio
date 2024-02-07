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
  card : texture2D
  
pub fun init-gui() : raylib-io guiState
  initWindow( windowWidth, windowHeight, "Economancy")
  guiSetStyle( guiControlDefault, guiControlPropertyTextSize, 16 * 4 )
  setTargetFPS( 60 )
  val card = loadTexture( "assets/sorcerers_stipend.png" )

  GuiState( MainMenu, card )

fun draw-phase( game-phase : phase ) : raylib-io ()
  val phase-text-width = raylib-MeasureText( game-phase.str, 44 )
  val phase-x = windowWidth - phase-text-width - 25
  drawText( game-phase.str, phase-x, 25, 44, darkgray )

fun draw-day( game-day : day ) : raylib-io ()
  val day-text = "DAY " ++ game-day.str
  drawText( day-text, 25, 25, 44, darkgray )

fun center( container-width : int, object-width : int ) : int
  container-width / 2 - object-width / 2

type playerLoc
  Bottom
  Top
  Left
  Right

fun get-player-coords( loc : playerLoc, container-width : int, container-height )
  val center-horizontal = center(windowWidth, container-width)
  val center-vertical = center(windowHeight, container-height)

  match loc
    gui/Bottom -> (center-horizontal, windowHeight - container-height)
    gui/Top -> (center-horizontal, 0)
    gui/Left -> (0, center-vertical)
    gui/Right -> (windowWidth - container-width, center-vertical)

fun draw-player( gui-state : guiState, loc : playerLoc, player : player )
  val container-width = windowWidth / 5
  val container-height = windowHeight / 4
  val (container-x, container-y) = get-player-coords( loc, container-width, container-height )

  // Name
  val name-font-size = 36
  val name-x = center(container-width, measureText( player.name, name-font-size ))
  drawText( player.name, container-x + name-x, container-y, name-font-size, darkgray )

  // Cards
  val card-width = container-width / 3
  val card-scale = float32(card-width.float64 / gui-state.card.width.float64)
  val card-height = int(gui-state.card.height.float64 * card-scale.float64)

  // TODO: Hard-coded to 1 card
  val cardX = float32(container-x + center(container-width, card-width))
  val cardPos = Vector2(cardX, float32(name-font-size + container-y))
  drawTextureEx(gui-state.card, cardPos, float32(0.0), card-scale, white)

  // Coins
  val coin-text = "Coins: " ++ player.coins.show
  drawText( coin-text, container-x + center(container-width, measureText(coin-text, name-font-size)), container-y + name-font-size + card-height, name-font-size, darkgray )

fun draw-players( gui-state : guiState, players : list<player> )
  val player-locs = [Bottom, Top, Left, Right]
  val players-and-locs = zip( players, player-locs )
  players-and-locs.map( fn( (p,l) ){ draw-player( gui-state, l, p )})

fun draw-player-income( gui-state : guiState, loc : playerLoc, player : player, income : int )
  val container-width = windowWidth / 5
  val container-height = windowHeight / 4
  val (container-x, container-y) = get-player-coords( loc, container-width, container-height )

  // Name
  val name-font-size = 36
  val name-x = center(container-width, measureText( player.name, name-font-size ))
  drawText( player.name, container-x + name-x, container-y, name-font-size, darkgray )

  // Cards
  val card-width = container-width / 3
  val card-scale = float32(card-width.float64 / gui-state.card.width.float64)
  val card-height = int(gui-state.card.height.float64 * card-scale.float64)

  // TODO: Hard-coded to 1 card
  val cardX = float32(container-x + center(container-width, card-width))
  val cardPos = Vector2(cardX, float32(name-font-size + container-y))
  drawTextureEx(gui-state.card, cardPos, float32(0.0), card-scale, white)

  // Coins
  val coin-text = "Coins: " ++ player.coins.show ++ " (+" ++ income.show ++ ")"
  drawText( coin-text, container-x + center(container-width, measureText(coin-text, name-font-size)), container-y + name-font-size + card-height, name-font-size, darkgray )

// TODO: This (and the function it calls) is VERY similar to draw-players. Figure out how to combine them.
fun draw-players-incomes( gui-state : guiState, players : list<player>, incomes : list<int> )
  val player-locs = [Bottom, Top, Left, Right]
  val players-locs-incomes = zip( zip(players, player-locs), incomes )
  players-locs-incomes.map( fn( ((p,l),i) ){ draw-player-income( gui-state, l, p, i )})

effect guiExit
  ctl exit() : a

pub fun get-player-info( gui-state : guiState ) : <raylib-io, guiExit> list<playerInitInfo>
  // TODO: For now, return a hard-coded list when start is clicked. Eventually, query for number of human and CPU players.

  val buttonWidth : float64 = windowWidth.float64 / 4.0
  val buttonHeight : float64 = windowHeight.float64 / 4.0
  val buttonXPos : float64 = windowWidth.float64 / 2.0 - buttonWidth / 2.0
  val buttonYPos : float64 = windowHeight.float64 / 2.0 - buttonHeight / 2.0
  val buttonRect = Rectangle( buttonXPos.float32, buttonYPos.float32, buttonWidth.float32, buttonHeight.float32 )

  fun get-player-info-r()
    if windowShouldClose() then exit()
    else
      clearBackground( raywhite )
      beginDrawing()

      val start-clicked = guiButton( buttonRect, "Start" )

      endDrawing()

      if start-clicked then 
        [PlayerInitInfo("Alice"), PlayerInitInfo("Bob"), PlayerInitInfo("Charlie"), PlayerInitInfo("Diane")]
      else
        get-player-info-r()

  get-player-info-r()

pub fun show-income-results( gui-state : guiState, game-state : gameState, player-incomes : list<int> ) : <raylib-io, guiExit> ()
    // When drawing coins, draw previous income and draw new income in green

  val buttonWidth : float64 = 300.0
  val buttonHeight : float64 = 150.0
  val buttonXPos : float64 = windowWidth.float64 - buttonWidth - 25.0
  val buttonYPos : float64 = windowHeight.float64 - buttonHeight - 25.0
  val buttonRect = Rectangle( buttonXPos.float32, buttonYPos.float32, buttonWidth.float32, buttonHeight.float32 )

  fun show-income-results-r()
    if windowShouldClose() then exit()
    else
      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw every player's info
      gui-state.draw-players-incomes( game-state.players, player-incomes )
      
      val next-clicked = guiButton( buttonRect, "Next" )

      endDrawing()

      if next-clicked then ()
      else show-income-results-r()

  show-income-results-r()
      
pub fun show-invest( gui-state : guiState, game-state : gameState ) : <raylib-io, guiExit> ()
  val buttonWidth : float64 = windowWidth.float64 / 4.0
  val buttonHeight : float64 = windowHeight.float64 / 4.0
  val buttonXPos : float64 = windowWidth.float64 / 2.0 - buttonWidth / 2.0
  val buttonYPos : float64 = windowHeight.float64 / 2.0 - buttonHeight / 2.0
  val buttonRect = Rectangle( buttonXPos.float32, buttonYPos.float32, buttonWidth.float32, buttonHeight.float32 )

  fun get-player-info-r()
    if windowShouldClose() then exit()
    else
      clearBackground( raywhite )
      beginDrawing()

      val start-clicked = guiButton( buttonRect, "Invest" )

      endDrawing()

      if start-clicked then ()
      else get-player-info-r()

  get-player-info-r()
      




