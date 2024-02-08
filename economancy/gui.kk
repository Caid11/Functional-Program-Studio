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

pub struct cardInfo
  ty : cardType
  tex : texture2D

pub struct guiState
  mode : guiMode
  cards : list<cardInfo>
  
pub fun init-gui() : raylib-io guiState
  initWindow( windowWidth, windowHeight, "Economancy")
  guiSetStyle( guiControlDefault, guiControlPropertyTextSize, 16 * 4 )
  setTargetFPS( 60 )

  val sorc_sti = CardInfo( SorcerersStipend, loadTexture( "assets/sorcerers_stipend.png" ) )
  val worker = CardInfo( Worker, loadTexture( "assets/worker.png" ) )
  val cards = [sorc_sti, worker]

  GuiState( MainMenu, cards )

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

fun get-card-stack-offsets( card-width : int, overlap : float64, num-cards : int ) : <pure> (list<float64>, int)
  val overlap-amt = card-width.float64 * overlap

  fun get-card-stack-offsets-r( num, offsets : list<float64>, curr-width )
    if num == 0 then (offsets, curr-width)
    else
      match offsets.last
        Nothing -> get-card-stack-offsets-r( num - 1, [0.0], card-width )
        Just( x ) -> get-card-stack-offsets-r( num - 1, offsets ++ [x + overlap-amt], curr-width + overlap-amt.int )

  get-card-stack-offsets-r( num-cards, [], 0 )

fun draw-player( gui-state : guiState, loc : playerLoc, player : player )
  val container-width = windowWidth / 5
  val container-height = windowHeight / 4
  val (container-x, container-y) = get-player-coords( loc, container-width, container-height )

  // Name
  val name-font-size = 36
  val name-x = center(container-width, measureText( player.name, name-font-size ))
  drawText( player.name, container-x + name-x, container-y, name-font-size, darkgray )

  // Cards
  val card = gui-state.cards.head.unjust
  val card-width = card.tex.width.float64
  val card-height  = card.tex.height.float64

  val card-tgt-width = float64(container-width / 3)
  val card-scale-factor = float32(card-tgt-width / card-width)
  val card-tgt-height = int(card-height * card-scale-factor.float64)

  // TODO: Hard-coded to 1 card
  val cardX = float32(container-x + center(container-width, card-tgt-width.int))
  val cardPos = Vector2(cardX, float32(name-font-size + container-y))
  drawTextureEx(card.tex, cardPos, float32(0.0), card-scale-factor, white)

  // Coins
  val coin-text = "Coins: " ++ player.coins.show
  drawText( coin-text, container-x + center(container-width, measureText(coin-text, name-font-size)), container-y + name-font-size + card-tgt-height, name-font-size, darkgray )

fun draw-players( gui-state : guiState, players : list<player> )
  val player-locs = [Bottom, Top, Left, Right]
  val players-and-locs = zip( players, player-locs )
  players-and-locs.map( fn( (p,l) ){ draw-player( gui-state, l, p )})

struct playerStackInfo
  name : string
  bounds : rectangle

fun draw-player-income( gui-state : guiState, loc : playerLoc, player : player, income : int ) : <raylib-io> playerStackInfo
  val container-width = windowWidth / 5
  val container-height = windowHeight / 4
  val (container-x, container-y) = get-player-coords( loc, container-width, container-height )

  // Name
  val name-font-size = 36
  val name-x = center(container-width, measureText( player.name, name-font-size ))
  drawText( player.name, container-x + name-x, container-y, name-font-size, darkgray )

  // Cards
  val card = gui-state.cards.head.unjust
  val card-width = card.tex.width.float64
  val card-height  = card.tex.height.float64

  val card-tgt-width = float64(container-width / 3)
  val card-scale-factor = float32(card-tgt-width / card-width)
  val card-tgt-height = int(card-height * card-scale-factor.float64)

  val (stack-offsets, stack-width) = get-card-stack-offsets( card-tgt-width.int, 0.3, player.cards.length )

  val stack-center-offset = center( container-width, stack-width )
  val card-y = float32( name-font-size + container-y )

  fun get-card-tex( c : cardType )
    gui-state.cards.filter( fn(c-info){ game/cardType/cmp(c-info.ty, c) }).head.unjust.tex

  fun draw-card( (c : cardType, offset : float64) )
    val card-x = float32(container-x + stack-center-offset + offset.int)
    val card-pos = Vector2(card-x, card-y)
    drawTextureEx( get-card-tex( c ), card-pos, float32(0.0), card-scale-factor, white)

  player.cards.zip( stack-offsets ).map( draw-card )

  // Coins
  val coin-text = "Coins: " ++ player.coins.show ++ " (+" ++ income.show ++ ")"
  drawText( coin-text, container-x + center(container-width, measureText(coin-text, name-font-size)), container-y + name-font-size + card-tgt-height, name-font-size, darkgray )

  PlayerStackInfo( player.name, Rectangle( float32( container-x + stack-center-offset), card-y, stack-width.float32, card-tgt-height.float32 ) )

// TODO: This (and the function it calls) is VERY similar to draw-players. Figure out how to combine them.
fun draw-players-incomes( gui-state : guiState, players : list<player>, incomes : list<int> ) : <raylib-io> list<playerStackInfo>
  val player-locs = [Bottom, Top, Left, Right]
  val players-locs-incomes = zip( zip(players, player-locs), incomes )
  val player-stacks = players-locs-incomes.map( fn( ((p,l),i) ){ draw-player-income( gui-state, l, p, i )})
  player-stacks

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

fun is-clicked( r : rectangle, p : vector2 ) : <> bool
  val left = r.x.float64
  val right = r.x.float64 + r.width.float64
  val top = r.y.float64
  val bottom = r.y.float64 + r.height.float64

  val pos-x = p.x.float64
  val pos-y = p.y.float64
  pos-x >= left && pos-x <= right && pos-y >= top && pos-y <= bottom

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
      val player-stacks = gui-state.draw-players-incomes( game-state.players, player-incomes )
      
      val next-clicked = guiButton( buttonRect, "Next" )

      if isMouseButtonPressed( mouseButtonLeft ) then
        val mousePos = getMousePosition()
        val clicked = player-stacks.filter( fn(s){ s.bounds.is-clicked( mousePos ) } )
        match clicked.head
          Just( p ) -> println(p.name)
          _ -> ()
      else ()

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
      




