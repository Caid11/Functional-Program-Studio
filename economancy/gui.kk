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

struct examinedCard
  player : string
  idx : int

pub struct mouseState
  last-x : int
  last-y : int
  frames-since-move : int

pub struct guiState
  mode : guiMode
  cards : list<cardInfo>
  mouse : mouseState
  
pub fun init-gui() : raylib-io guiState
  initWindow( windowWidth, windowHeight, "Economancy")
  guiSetStyle( guiControlDefault, guiControlPropertyTextSize, 16 * 4 )
  setTargetFPS( 60 )

  val cards = [
    CardInfo( SorcerersStipend, loadTexture( "assets/sorcerers_stipend.png" ) ),
    CardInfo( Apprentice, loadTexture( "assets/apprentice.png" ) ),
    CardInfo( BoardOfMonopoly, loadTexture( "assets/board_of_monopoly.png" ) ),
    CardInfo( Bubble, loadTexture( "assets/bubble.png" ) ),
    CardInfo( Ghost, loadTexture( "assets/ghost.png" ) ),
    CardInfo( GoldFish, loadTexture( "assets/gold_fish.png" ) ),
    CardInfo( Golem, loadTexture( "assets/golem.png" ) ),
    CardInfo( Incantation, loadTexture( "assets/incantation.png" ) ),
    CardInfo( MagicBeanStock, loadTexture( "assets/magic_bean_stock.png" ) ),
    CardInfo( SeniorWorker, loadTexture( "assets/senior_worker.png" ) ),
    CardInfo( ShieldOfGreed, loadTexture( "assets/shield_of_greed.png" ) ),
    CardInfo( Thug, loadTexture( "assets/thug.png" ) ),
    CardInfo( WallOfWealth, loadTexture( "assets/wall_of_wealth.png" ) ),
    CardInfo( Worker, loadTexture( "assets/worker.png" ) ),
  ]

  GuiState( MainMenu, cards, MouseState( 0, 0, 0 ) )

fun update-mouse( gui-state : guiState ) : raylib-io guiState
  val curr-mouse-pos = getMousePosition()
  val curr-x = curr-mouse-pos.x.float64.int
  val curr-y = curr-mouse-pos.y.float64.int

  val prev = gui-state.mouse

  val new-mouse = if curr-x == prev.last-x && curr-y == prev.last-y then
    prev( frames-since-move = prev.frames-since-move + 1 )
  else
    MouseState( curr-x, curr-y, 0 )
  
  gui-state( mouse = new-mouse )

val mouse-over-frames = int(60.0 * 0.5)

val phase-day-size = 60

fun draw-phase( game-phase : phase ) : raylib-io ()
  val phase-text-width = raylib-MeasureText( game-phase.str, phase-day-size )
  val phase-x = windowWidth - phase-text-width - 25
  drawText( game-phase.str, phase-x, 25, phase-day-size, darkgray )

fun draw-day( game-day : day ) : raylib-io ()
  val day-text = "DAY " ++ game-day.str
  drawText( day-text, 25, 25, phase-day-size, darkgray )

fun center( container-width : int, object-width : int ) : int
  container-width / 2 - object-width / 2

type playerLoc
  Bottom
  Top
  Left
  Right

fun get-player-coords( loc : playerLoc )
  val horiz-margin = 150
  val vert-margin = 125
  val center-horizontal = windowWidth / 2
  val center-vertical = int(windowHeight.float64 / 2.5)

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

struct cardScaleInfo
  width : int
  height : int
  scale-factor : float64

fun scale-card( gui-state : guiState, tgt-width : int ) : pure cardScaleInfo
  val scale-factor = tgt-width.float64 / gui-state.card-width
  val tgt-height = int( gui-state.card-height * scale-factor )
  CardScaleInfo( tgt-width, tgt-height, scale-factor )

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
    Just( i ) -> 
      val sign-str = if i > 0 then "+" else ""
      coin-str ++ " (" ++ sign-str ++ i.show ++ ")"

pub struct bounds
  x : int
  y : int
  width : int
  height : int

fun draw-card( gui-state : guiState,
               card : cardType,
               x-pos : int,
               y-pos : int,
               tgt-width : int,
               highlight-color : color ) : raylib-io bounds
  val scaled = gui-state.scale-card( tgt-width )
  val pos = Vector2( x-pos.float32, y-pos.float32 )
  drawTextureEx( gui-state.get-card-tex( card ), pos, float32(0.0), scaled.scale-factor.float32, highlight-color )

  Bounds( x-pos, y-pos, scaled.width, scaled.height)

struct cardBounds
  b : bounds
  t : cardType

struct playerStackInfo
  name : string
  bounds : list<cardBounds>

fun draw-player( gui-state : guiState,
                 loc : playerLoc,
                 player : player,
                 active-player : maybe<string>,
                 income : maybe<int> = Nothing ) : <raylib-io> playerStackInfo
  val name-font-size = 36
  val coins-font-size = 36

  val card-scaled = gui-state.scale-card( 100 )
  val card-overlap = 0.3

  val (player-center-x, player-center-y) = get-player-coords( loc )

  val coins-text = coin-text( player.coins, income )

  val name-x = center-text( player-center-x, player.name, name-font-size )
  val (stack-xs, stack-width) = center-cards( player-center-x, card-scaled.width, card-overlap, player.cards.length )
  val coins-x = center-text( player-center-x, coins-text, coins-font-size )

  val player-height = [name-font-size, card-scaled.height, coins-font-size].sum
  val center-y-offset = player-height / 2

  val name-y = player-center-y - center-y-offset
  val stack-y = name-y + name-font-size
  val coins-y = stack-y + card-scaled.height

  val name-color = match active-player
    Nothing -> darkgray
    Just( n ) -> if n == player.name then green else darkgray

  drawText( player.name, name-x, name-y, name-font-size, name-color )

  val card-bounds = player.cards.zip( stack-xs ).map-indexed( fn( i, (c, x) ){
    val bounds = gui-state.draw-card( c, x, stack-y, card-scaled.width, white )
    CardBounds( bounds, c ) })

  drawText( coins-text, coins-x, coins-y, coins-font-size, darkgray )

  PlayerStackInfo( player.name, card-bounds.reverse )

fun draw-players( gui-state : guiState,
                  players : list<player>,
                  active-player : maybe<string> = Nothing,
                  maybe-incomes : maybe<list<int>> = Nothing ) : <raylib-io> list<playerStackInfo>
  val player-locs = [Bottom, Top, Left, Right]
  match maybe-incomes
    Just( incomes ) ->
      val players-locs-incomes = zip( zip(players, player-locs), incomes )
      val player-stacks = players-locs-incomes.map( fn( ((p,l),i) ){ draw-player( gui-state, l, p, active-player, Just( i ) )})
      player-stacks
    Nothing ->
      val players-locs = zip( players, player-locs )
      val player-stacks = players-locs.map( fn( (p,l) ){ draw-player( gui-state, l, p, active-player )})
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
        [PlayerInitInfo("Alice", Human), PlayerInitInfo("Bob", Human), PlayerInitInfo("Charlie", Cpu), PlayerInitInfo("Diane", Cpu)]
      else
        get-player-info-r()

  get-player-info-r()

fun is-over( r : bounds, x-pos : int, y-pos : int ) : <> bool
  val left = r.x
  val right = r.x + r.width
  val top = r.y
  val bottom = r.y + r.height

  x-pos >= left && x-pos <= right && y-pos >= top && y-pos <= bottom

fun is-clicked( r : rectangle, p : vector2 ) : <> bool
  val left = r.x.float64
  val right = r.x.float64 + r.width.float64
  val top = r.y.float64
  val bottom = r.y.float64 + r.height.float64

  val pos-x = p.x.float64
  val pos-y = p.y.float64
  pos-x >= left && pos-x <= right && pos-y >= top && pos-y <= bottom

fun card-chooser( gui-state : guiState,
                  possible-cards : list<cardType>,
                  card-idx : int,
                  pos-x : int,
                  pos-y : int,
                  card-tgt-width : int ) : raylib-io int
  val card-scaled = gui-state.scale-card( card-tgt-width )

  val switch-button-width = card-tgt-width / 3
  val padding = 25

  val switch-left-x = 0
  val card-x = switch-left-x + switch-button-width + padding
  val switch-right-x = card-x + card-scaled.width + padding
  val chooser-width = [switch-button-width, padding, card-scaled.width, padding, switch-button-width].sum
  val center-offset-x = chooser-width / 2

  val switch-offset-y = switch-button-width / 2
  val card-offset-y = card-scaled.height / 2

  val left-switch-rect = Rectangle( float32(pos-x - center-offset-x), 
                                    float32(pos-y - switch-offset-y),
                                    switch-button-width.float32, switch-button-width.float32 )
  val switch-left-clicked = guiButton( left-switch-rect, "<" )

  val card-pos = Vector2( float32(pos-x - center-offset-x + card-x),
                          float32(pos-y - card-offset-y))

  val card-ty = possible-cards[card-idx].unjust
  drawTextureEx( get-card-tex( gui-state, card-ty ), card-pos, float32(0.0), card-scaled.scale-factor.float32, white )

  val right-switch-rect = Rectangle( float32(pos-x - center-offset-x + switch-right-x), 
                                     float32(pos-y - switch-offset-y),
                                     switch-button-width.float32, switch-button-width.float32 )
  val switch-right-clicked = guiButton( right-switch-rect, ">" )

  val num-cards = possible-cards.length

  val new-card-idx = 
    if switch-left-clicked then 
      if card-idx == 0 then num-cards - 1
      else card-idx - 1
    else if switch-right-clicked then (card-idx + 1) % num-cards
    else card-idx

  new-card-idx

fun get-player( game-state : gameState, player-name : string )
  game-state.players.find( fn( p ){ p.name == player-name }).unjust

fun get-player-card( game-state : gameState, player-name : string, card-idx : int )
  game-state.get-player( player-name ).cards[card-idx].unjust

fun next-btn() : raylib-io bool
  val btn-width : float64 = 300.0
  val btn-height : float64 = 150.0

  val btn-x : float64 = windowWidth.float64 - btn-width - 25.0
  val btn-y : float64 = windowHeight.float64 - btn-height - 25.0

  val btn-pos = Rectangle( btn-x.float32, btn-y.float32, btn-width.float32, btn-height.float32 )

  guiButton( btn-pos, "Next" )

fun draw-mouse-over( gui-state : guiState, card : cardType, x-pos : int, y-pos : int ) : raylib-io ()
  val card-scaled = gui-state.scale-card( 300 )

  val card-x = if x-pos > windowWidth / 2 then x-pos - card-scaled.width else x-pos
  val card-y = if y-pos > windowHeight / 2 then y-pos - card-scaled.height else y-pos

  gui-state.draw-card( card, card-x, card-y, card-scaled.width, white)
  ()

pub fun hover-card( gui-state : guiState, bounds : list<cardBounds> ) : raylib-io ()
  val x-pos = gui-state.mouse.last-x
  val y-pos = gui-state.mouse.last-y

  if gui-state.mouse.frames-since-move >= mouse-over-frames then
    val moused-over = bounds.find( fn(cb){ is-over( cb.b, x-pos, y-pos )})
    match moused-over
      Nothing -> ()
      Just( CardBounds( _, ty ) ) -> gui-state.draw-mouse-over( ty, x-pos, y-pos )
  else ()

pub fun show-income-results( init-gui-state : guiState, game-state : gameState, player-incomes : list<int> ) : <raylib-io, guiExit> guiState
  fun show-income-results-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw player cards
      val player-stacks = gui-state.draw-players( game-state.players, Nothing, Just( player-incomes ) )

      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })
      gui-state.hover-card( stack-bounds )

      val next-clicked = next-btn()

      endDrawing()

      if next-clicked then gui-state
      else show-income-results-r( gui-state )

  show-income-results-r( init-gui-state )
      
pub fun get-investment( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, int)
  val padding = 25

  val adjust-center-x = windowWidth / 2
  val adjust-center-y = windowHeight / 2

  val adjust-btn-width = 75
  val invest-font-size = adjust-btn-width

  val num-coins = game-state.get-player( player-name ).coins

  fun get-investment-r( prev-gui-state : guiState, curr-invest : int )
    val adjust-down-x = 0
    val invest-x = adjust-down-x + adjust-btn-width + padding
    val adjust-up-x = invest-x + measureText( curr-invest.show, invest-font-size ) + padding
    val total-width = adjust-up-x + adjust-btn-width
    val center-x-offset = total-width / 2

    val total-height = [adjust-btn-width, padding, adjust-btn-width].sum
    val center-y-offset = total-height / 2

    val adjust-down-pos = Rectangle( float32(adjust-center-x - center-x-offset + adjust-down-x),
                                    float32(adjust-center-y - center-y-offset),
                                    float32(adjust-btn-width),
                                    float32(adjust-btn-width))

    val invest-text-x = adjust-center-x - center-x-offset + invest-x
    val invest-text-y = adjust-center-y - center-y-offset

    val adjust-up-pos = Rectangle( float32(adjust-center-x - center-x-offset + adjust-up-x),
                                    float32(adjust-center-y - center-y-offset),
                                    float32(adjust-btn-width),
                                    float32(adjust-btn-width))

    val invest-btn-pos = Rectangle( float32(adjust-center-x - center-x-offset),
                                    float32(adjust-center-y - center-y-offset + padding + adjust-btn-width),
                                    float32(total-width),
                                    float32(adjust-btn-width))

    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw player cards
      val player-stacks = gui-state.draw-players( game-state.players, Just( player-name ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      // Draw invest controls
      val down-clicked = guiButton( adjust-down-pos, "-" )
      drawText( curr-invest.show, invest-text-x, invest-text-y, invest-font-size, darkgray )
      val up-clicked = guiButton( adjust-up-pos, "+" )
      val invest-clicked = guiButton( invest-btn-pos, "Invest" )

      val new-invest = if down-clicked then
        [0, curr-invest - 1].maximum
      else if up-clicked then
        [num-coins, curr-invest + 1].minimum
      else curr-invest

      gui-state.hover-card( stack-bounds )

      endDrawing()

      if invest-clicked then (gui-state, curr-invest)
      else get-investment-r( gui-state, new-invest )

  get-investment-r( init-gui-state, 0 )

pub fun show-invest-results( init-gui-state : guiState, game-state : gameState, invest-result : investResult ) : <raylib-io, guiExit> guiState
  fun show-invest-results-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )

      val player-incomes = invest-result.investments.map( fn( invest ){ invest * -1 } )
    
      // Draw player cards
      val player-stacks = gui-state.draw-players( game-state.players, Nothing, Just( player-incomes ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      // Draw invest winner (or indicate that no one one)
      val winner-text = match invest-result.winner-name
        Nothing -> "No one wins"
        Just( name ) -> name ++ " wins!"
      
      val center-x = windowWidth / 2
      val center-y = windowHeight / 2

      val winner-text-size = 125

      val center-x-offset = measureText( winner-text, winner-text-size ) / 2
      val center-y-offset = winner-text-size / 2

      val winner-x = center-x - center-x-offset
      val winner-y = center-y - center-y-offset

      drawText( winner-text, winner-x, winner-y, winner-text-size, darkgray )

      val next-clicked = next-btn()

      gui-state.hover-card( stack-bounds )

      endDrawing()

      if next-clicked then gui-state
      else show-invest-results-r( gui-state )

  show-invest-results-r( init-gui-state )

pub fun get-attack-card( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, maybe<int>)
  val padding = 25

  // TODO: Make card-chooser return width and height so we can place elements around it

  val center-x = windowWidth / 2
  val center-y = windowHeight / 2

  val attacker-name = game-state.attacker.unjust
  val choose-text = if attacker-name == player-name then "Choose attacker" else "Choose defender"
  val choose-font-size = 60

  val chooser-card-width = 300
  
  val choose-text-x = center-x - measureText( choose-text, choose-font-size ) / 2
  val choose-text-y = 230

  val possible-cards = game-state.get-player( player-name ).cards

  val btn-width = 300.0
  val btn-height = 150.0

  val btn-x : float64 = windowWidth.float64 - btn-width - 25.0

  val pass-btn-y : float64 = windowHeight.float64 - btn-height - 25.0
  val choose-btn-y : float64 = pass-btn-y - 25.0 - btn-height

  val pass-btn-pos = Rectangle( btn-x.float32, pass-btn-y.float32, btn-width.float32, btn-height.float32 )
  val choose-btn-pos = Rectangle( btn-x.float32, choose-btn-y.float32, btn-width.float32, btn-height.float32 )

  fun get-attack-card-r( prev-gui-state : guiState, curr-card-idx : int )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw player cards
      val player-stacks = gui-state.draw-players( game-state.players, Just( player-name ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      drawText( choose-text, choose-text-x, choose-text-y, choose-font-size, darkgray )

      // TODO: Add effects (e.g. fainted, cannot attack, twice attack, etc.) to cards and only allow choosing if legal
      // TODO: Highlight selected attack/defend card in red

      val new-card-idx = gui-state.card-chooser( possible-cards,
                                                 curr-card-idx,
                                                 center-x,
                                                 center-y - 15,
                                                 chooser-card-width )

      val choose-clicked = guiButton( choose-btn-pos, "Choose" )
      val pass-clicked = guiButton( pass-btn-pos, "Pass" )

      gui-state.hover-card( stack-bounds )

      endDrawing()

      val new-gui-state = gui-state

      if pass-clicked then (new-gui-state, Nothing)
      else if choose-clicked then (new-gui-state, Just( curr-card-idx ))
      else get-attack-card-r( new-gui-state, new-card-idx )

  get-attack-card-r( init-gui-state, 0 )

pub fun show-attack-results( init-gui-state : guiState, game-state : gameState, attack-result : attackResult) : <raylib-io, guiExit> guiState
  fun draw-player-choice( gui-state : guiState, player-name : string, card-ty : cardType, pos-x : int, pos-y : int, card-tgt-width : int )
    val name-size = 30
    val player-text-width = measureText( player-name, name-size )

    val padding = 10
    
    val card-scaled = gui-state.scale-card( card-tgt-width )

    val total-height = [name-size, padding, card-scaled.height].sum
    val center-y-offset = total-height / 2

    val name-x = pos-x - player-text-width / 2
    val name-y = pos-y - center-y-offset

    val card-x = pos-x - card-scaled.width / 2
    val card-y = name-y + padding + name-size

    drawText( player-name, name-x, name-y, name-size, darkgray )
    CardBounds( gui-state.draw-card( card-ty, card-x, card-y, card-scaled.width, white ), card-ty )

  fun show-attack-results-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )

      val choice-width = 175
      val center-y = windowHeight / 2

      val start-x = 250
      val attacker-bounds = draw-player-choice( gui-state,
                                                attack-result.attacker-name,
                                                attack-result.attacker-card,
                                                start-x, center-y,
                                                choice-width )

      val vs-x = start-x + choice-width / 2 + 25
      val vs-size = 75
      val vs-y = center-y - vs-size / 2
      drawText("VS", vs-x, vs-y, vs-size, darkgray)

      val defender-x = vs-x + measureText( "VS", vs-size ) + 25 + choice-width / 2

      val defenders = game-state.players.filter( fn(p){p.name != attack-result.attacker-name} )
      val defenders-and-choices = defenders.zip( attack-result.defender-cards )

      val defender-offset = center-y / 2 + 50
      val defender-y-pos = [center-y - defender-offset, center-y, center-y + defender-offset]

      val defenders-choice-pos = defenders-and-choices.zip( defender-y-pos )

      // TODO: This feels like an antipattern. Explore a better data structure
      val defenders-choice-pos-outcome = defenders-choice-pos.zip( attack-result.outcomes )

      val equals-x = defender-x + choice-width / 2 + 25

      val outcome-x = equals-x + measureText( "=", vs-size ) + 25

      val defender-bounds = defenders-choice-pos-outcome.map( fn( (((player, choice), y-pos), outcome) ) {
        val card-bounds = draw-player-choice( gui-state, player.player/name, choice, defender-x, y-pos, choice-width )
        drawText( "=", equals-x, y-pos, vs-size, darkgray )

        val outcome-text = match outcome
          DrawNoFaint -> "Draw"
          DrawBothFaint -> "Both cards fainted!"
          AttackerFainted -> attack-result.attacker-name ++ "'s card fainted!"
          DefenderFainted -> player.player/name ++ "'s card fainted!"
          DefenderDefeated -> player.player/name ++ " is defeated!"

        drawText( outcome-text, outcome-x, y-pos, vs-size, darkgray )

        card-bounds
      })

      val next-clicked = next-btn()

      val card-bounds = [attacker-bounds] ++ defender-bounds
      gui-state.hover-card( card-bounds )

      endDrawing()

      if next-clicked then gui-state
      else show-attack-results-r( gui-state )

  show-attack-results-r( init-gui-state )

pub fun get-buy-card( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, maybe<cardType>)
  val center-x = windowWidth / 2
  val center-y = windowHeight / 2

  // TODO: Duplicated from get-attack
  val btn-width = 300.0
  val btn-height = 150.0

  val btn-x : float64 = windowWidth.float64 - btn-width - 25.0

  val pass-btn-y : float64 = windowHeight.float64 - btn-height - 25.0
  val choose-btn-y : float64 = pass-btn-y - 25.0 - btn-height

  val pass-btn-pos = Rectangle( btn-x.float32, pass-btn-y.float32, btn-width.float32, btn-height.float32 )
  val choose-btn-pos = Rectangle( btn-x.float32, choose-btn-y.float32, btn-width.float32, btn-height.float32 )

  fun get-buy-card-r( prev-gui-state : guiState, curr-card : maybe<cardType> )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw player cards and examined card
      val player-stacks = gui-state.draw-players( game-state.players, Just( player-name ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      // Draw store cards

      val card-scaled = gui-state.scale-card( 150 )

      val start-x = 300
      val start-y = 250
      val padding = 20

      val num-cards-in-row = 7

      fun draw-stock( s : list<stock>, x-pos : int, y-pos : int, row-idx : int, bounds : list<cardBounds> )
        match s
          Nil -> bounds
          Cons( Stock( card, num ), rest ) ->
            val highlight-color = match curr-card
              Nothing -> white
              Just( ty ) -> if game/cardType/cmp(ty, card) then yellow else white

            val card-bounds = gui-state.draw-card( card, x-pos, y-pos, card-scaled.width, highlight-color )

            val num-remaining-text = "Remaining: " ++ num.show
            val num-remaining-height = 20
            val num-remaining-width = measureText( num-remaining-text, num-remaining-height )
            val stock-x = card-bounds.x + (card-bounds.width / 2) - (num-remaining-width / 2)
            val stock-y = card-bounds.y + card-bounds.height + 10
            drawText( num-remaining-text, stock-x, stock-y, num-remaining-height, darkgray )

            val new-row-idx = (row-idx + 1) % num-cards-in-row
            val new-x-pos = if new-row-idx > row-idx then x-pos + card-scaled.width + padding else start-x
            val new-y-pos = if new-row-idx > row-idx then y-pos else stock-y + num-remaining-height + padding

            val new-bounds = CardBounds( card-bounds, card )
            draw-stock( rest, new-x-pos, new-y-pos, new-row-idx, bounds ++ [new-bounds] )

      val stock-bounds = draw-stock( game-state.store, start-x, start-y, 0, [] )

      val new-card = if isMouseButtonPressed( mouseButtonLeft ) then
        val clicked-card = stock-bounds.find( fn(cb){ is-over( cb.b, gui-state.mouse.last-x, gui-state.mouse.last-y ) })
        match clicked-card
          Nothing -> curr-card
          Just( CardBounds(_, ty ) ) -> Just( ty )
      else curr-card

      val choose-clicked = guiButton( choose-btn-pos, "Choose" )
      val pass-clicked = guiButton( pass-btn-pos, "Pass" )

      val all-bounds = stack-bounds ++ stock-bounds
      gui-state.hover-card( all-bounds )

      endDrawing()

      val new-gui-state = gui-state

      // TODO: Don't allow clicking choose if no card selected
      // TODO: Don't allow choosing cards with 0 stock.

      if pass-clicked then (gui-state, curr-card)
      else if choose-clicked then (new-gui-state, curr-card)
      else get-buy-card-r( gui-state, new-card )

  get-buy-card-r( init-gui-state, Nothing )

pub fun show-buy-results( init-gui-state : guiState, game-state : gameState, buy-result : buyResult ) : <raylib-io, guiExit> guiState
  fun show-buy-results-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw player cards
      val player-incomes = buy-result.purchase-amts.map( fn(x){ x * -1 })
      val player-stacks = gui-state.draw-players( game-state.players, Nothing, Just( player-incomes ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      // Draw purchased cards.
      val scaled = gui-state.scale-card( 200 )
      val padding = 15

      val offsets = list(0,3).map( fn(x){ x * (scaled.width + padding)})
      val total-width = offsets.maximum + scaled.width
      val center-x-offset = total-width / 2

      val name-size = 44
      val height = name-size + padding + scaled.height
      val center-y-offset = height / 2

      val center-x = windowWidth / 2
      val center-y = windowHeight / 2

      offsets.map-indexed( fn(i, x){
        val name-y = center-y - center-y-offset
        val name = game-state.players[i].unjust.name
        val name-width = measureText( name, name-size )
        val name-x = center-x - center-x-offset + x + scaled.width / 2 - name-width / 2
        drawText( name, name-x, name-y, name-size, darkgray )

        val highlight-color = if buy-result.purchase-conflict[i].unjust then red else white

        val card-y = name-y + name-size + padding
        val card-x = center-x - center-x-offset + x
        val card = buy-result.cards[i].unjust
        match card
          Nothing -> ()
          Just( ty ) ->
            gui-state.draw-card( ty, card-x, card-y, scaled.width, highlight-color )
            ()
      })

      val next-clicked = next-btn()

      gui-state.hover-card( stack-bounds )

      endDrawing()

      if next-clicked then gui-state
      else show-buy-results-r( gui-state )

  show-buy-results-r( init-gui-state )
