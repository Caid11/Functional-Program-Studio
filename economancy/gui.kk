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

fun get-player-coords( loc : playerLoc )
  val horiz-margin = 150
  val vert-margin = 100
  val center-horizontal = windowWidth / 2
  val center-vertical = windowHeight / 2

  match loc
    gui/Bottom -> (center-horizontal, windowHeight - vert-margin)
    gui/Top -> (center-horizontal, vert-margin)
    gui/Left -> (horiz-margin, center-vertical)
    gui/Right -> (windowWidth - horiz-margin, center-vertical)

fun card-width( gui-state : guiState ) : <exn> float64
  val card = gui-state.cards.head.unjust
  card.tex.width.float64

fun card-height( gui-state : guiState ) : <exn> float64
  val card = gui-state.cards.head.unjust
  card.tex.height.float64

fun get-card-tex( gui-state : guiState, c : cardType )
  gui-state.cards.filter( fn(c-info){ game/cardType/cmp(c-info.ty, c) }).head.unjust.tex

fun center-text( x-pos : int, text : string, font-size : int )
  x-pos - text.measureText( font-size ) / 2

fun center-cards( x-pos : int, card-width : int, overlap : float64, num-cards : int ) : <pure> (list<int>, int)
  val overlap-amt = card-width.float64 * overlap

  fun center-cards-r( num, xs : list<int>, curr-width )
    if num == 0 then (xs, curr-width)
    else
      match xs.last
        Nothing -> center-cards-r( num - 1, [0], card-width )
        Just( x ) -> center-cards-r( num - 1, xs ++ [x + overlap-amt.int], curr-width + overlap-amt.int )

  val (offsets, width) = center-cards-r( num-cards, [], 0 )
  val stack-offset = width / 2

  (offsets.map( fn( x ){ x-pos + x - stack-offset }), width)

fun coin-text( coins : int, income : maybe<int> ) : <> string
  val coin-str = "Coins: " ++ coins.show
  match income
    Nothing -> coin-str
    Just( i ) -> coin-str ++ " (+" ++ i.show ++ ")"

struct playerStackInfo
  name : string
  bounds : rectangle

fun draw-player( gui-state : guiState,
                 loc : playerLoc,
                 player : player,
                 selected-idx : maybe<int> = Nothing,
                 income : maybe<int> = Nothing ) : <raylib-io> playerStackInfo
  val name-font-size = 36
  val coins-font-size = 36

  val card-tgt-width = 100
  val card-scale-factor = card-tgt-width.float64 / gui-state.card-width
  val card-tgt-height = int( gui-state.card-height * card-scale-factor )
  val card-overlap = 0.3

  val (player-center-x, player-center-y) = get-player-coords( loc )

  val coins-text = coin-text( player.coins, income )

  val name-x = center-text( player-center-x, player.name, name-font-size )
  val (stack-xs, stack-width) = center-cards( player-center-x, card-tgt-width, card-overlap, player.cards.length )
  val coins-x = center-text( player-center-x, coins-text, coins-font-size )

  val player-height = [name-font-size, card-tgt-height, coins-font-size].sum
  val center-y-offset = player-height / 2

  val name-y = player-center-y - center-y-offset
  val stack-y = name-y + name-font-size
  val coins-y = stack-y + card-tgt-height

  drawText( player.name, name-x, name-y, name-font-size, darkgray )

  player.cards.zip( stack-xs ).map( fn( (c, x) ){
    val pos = Vector2( x.float32, stack-y.float32 )
    drawTextureEx( get-card-tex( gui-state, c ), pos, float32(0.0), card-scale-factor.float32, white ) })

  drawText( coins-text, coins-x, coins-y, coins-font-size, darkgray )

  val stackBounds = Rectangle(stack-xs.head.unjust.float32, stack-y.float32, stack-width.float32, card-tgt-height.float32)
  PlayerStackInfo( player.name, stackBounds )

// TODO: This (and the function it calls) is VERY similar to draw-players. Figure out how to combine them.
fun draw-players-incomes( gui-state : guiState, players : list<player>, incomes : list<int> ) : <raylib-io> list<playerStackInfo>
  val player-locs = [Bottom, Top, Left, Right]
  val players-locs-incomes = zip( zip(players, player-locs), incomes )
  val player-stacks = players-locs-incomes.map( fn( ((p,l),i) ){ draw-player( gui-state, l, p, Nothing, Just( i ) )})
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