import std/num/float64
import std/core/debug

import raylib/raylib

import game
import cpu-player
import player-info

fun unjust( x : maybe<a>, line : string ) : exn a
  match x
    Just( y ) -> y
    Nothing ->
      val msg = "unexpected Nothing in unjust at " ++ line
      throw(msg)

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
  val phase-text-width = raylib-MeasureText( game-phase.show, phase-day-size )
  val phase-x = windowWidth - phase-text-width - 25
  drawText( game-phase.show, phase-x, 25, phase-day-size, darkgray )

fun draw-day( game-day : day ) : raylib-io ()
  val day-text = "DAY " ++ game-day.show
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
  val card = gui-state.cards.head.gui/unjust( kk-line )
  card.tex.width.float64

fun card-height( gui-state : guiState ) : <exn> float64
  val card = gui-state.cards.head.gui/unjust( kk-line )
  card.tex.height.float64

fun get-card-tex( gui-state : guiState, c : cardType )
  gui-state.cards.filter( fn(c-info){ c-info.ty == c }).head.gui/unjust( kk-line ).tex

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

val player-name-font-size = 36

fun draw-defeated-player( gui-state : guiState,
                          loc : playerLoc,
                          player : player ) : <raylib-io> ()
  val (player-center-x, player-center-y) = get-player-coords( loc )

  val padding = 5

  val name-x = center-text( player-center-x, player.name, player-name-font-size )

  val defeated-text = "DEFEATED"
  val defeated-x = center-text( player-center-x, defeated-text, player-name-font-size )

  val total-height = [player-name-font-size, padding, player-name-font-size].sum
  val center-y-offset = total-height / 2

  val name-y = player-center-y - center-y-offset
  val defeated-y = name-y + player-name-font-size + padding 

  drawText( player.name, name-x, name-y, player-name-font-size, darkgray )
  drawText( defeated-text, defeated-x, defeated-y, player-name-font-size, red )

fun draw-active-player( gui-state : guiState,
                        loc : playerLoc,
                        player : player,
                        active-player : maybe<string>,
                        income : maybe<int>,
                        attacker : maybe<string>,
                        attacker-card-idx : maybe<int> ) : <raylib-io> playerStackInfo
  val coins-font-size = 36

  val card-scaled = gui-state.scale-card( 100 )
  val card-overlap = 0.3

  val (player-center-x, player-center-y) = get-player-coords( loc )

  val coins-text = coin-text( player.coins, income )

  val padding = 5

  val name-x = center-text( player-center-x, player.name, player-name-font-size )
  val (stack-xs, stack-width) = center-cards( player-center-x, card-scaled.width, card-overlap, player.cards.length )
  val coins-x = center-text( player-center-x, coins-text, coins-font-size )

  val player-height = [player-name-font-size, padding, card-scaled.height, padding, coins-font-size].sum
  val center-y-offset = player-height / 2

  val name-y = player-center-y - center-y-offset
  val stack-y = name-y + padding + player-name-font-size
  val coins-y = stack-y + padding + card-scaled.height

  val name-color = match active-player
    Nothing -> darkgray
    Just( n ) -> if n == player.name then green else darkgray

  drawText( player.name, name-x, name-y, player-name-font-size, name-color )

  val card-bounds = player.cards.zip( stack-xs ).map-indexed( fn( i, (c, x) ){
    val is-attacker = match attacker
      Nothing -> False
      Just( attacker-name ) -> attacker-name == player.name

    // Make card gray if tapped, red if attacker and card is attacking
    val is-tapped = if is-attacker then c.attacks == 0 else c.defends == 0
    val tapped-color = if is-tapped then gray else white

    // val draw-color = tapped-color
    val is-attacking-card = match attacker-card-idx
      Nothing -> False
      Just( idx ) -> idx == i

    val attack-color = if is-attacker then
      if is-attacking-card then red
      else tapped-color
    else tapped-color

    val draw-color = if attacker.is-just then attack-color else white

    val bounds = gui-state.draw-card( c.ty, x, stack-y, card-scaled.width, draw-color )
    CardBounds( bounds, c.ty ) })

  drawText( coins-text, coins-x, coins-y, coins-font-size, darkgray )

  PlayerStackInfo( player.name, card-bounds.reverse )

fun draw-players( gui-state : guiState,
                  players : list<player>,
                  active-player : maybe<string> = Nothing,
                  maybe-incomes : maybe<list<int>> = Nothing,
                  attacker : maybe<string> = Nothing,
                  attacker-card-idx : maybe<int> = Nothing ) : <raylib-io> list<playerStackInfo>
  val player-locs = [Bottom, Top, Left, Right]
  val players-with-locs = players.zip( player-locs )

  val defeated-players = players-with-locs.filter( fn( (p,l) ){ p.status.is-defeated })
  defeated-players.map( fn( (p,l) ){ draw-defeated-player( gui-state, l, p ) })

  val active-players = players-with-locs.filter( fn( (p,l) ){ p.status.is-playing })

  match maybe-incomes
    Just( incomes ) ->
      val players-locs-incomes = active-players.zip( incomes )
      val player-stacks = players-locs-incomes.map( fn( ((p,l),i) ){ draw-active-player( gui-state, l, p, active-player, Just( i ), attacker, attacker-card-idx )})
      player-stacks
    Nothing ->
      val player-stacks = active-players.map( fn( (p,l) ){ draw-active-player( gui-state, l, p, active-player, Nothing, attacker, attacker-card-idx )})
      player-stacks

effect guiExit
  ctl exit() : a

pub fun get-player-info( gui-state : guiState ) : <raylib-io, guiExit> list<playerInitInfo>
  val (num-human-players, num-cpu-players) = gui-state.get-player-counts()
  gui-state.collect-player-info( num-human-players, num-cpu-players )

fun collect-player-info( gui-state : guiState, num-humans : int, num-cpus : int ) : <raylib-io, guiExit> list<playerInitInfo>
  val interior-padding = 10
  val exterior-padding = 25

  val option-size = 60
  val adjust-btn-size = option-size

  val name-lbl = "Name: "
  val name-lbl-width = measureText( name-lbl, option-size )
  
  val max-name-length = 10
  val max-name-width = measureText( list(1,max-name-length).map( fn(_){ 'X' } ).string, option-size )
  
  val total-name-width = [name-lbl-width, interior-padding, max-name-width].sum
  val name-center-x-offset = total-name-width / 2

  val center-x = windowWidth / 2
  val center-y = windowHeight / 2

  val name-lbl-x = center-x - name-center-x-offset
  val name-input-x = name-lbl-x + name-lbl-width + interior-padding

  // TODO: Allow selecting different CPU strategies.

  fun human-info( y-pos : int, name : string, active : bool )
    drawText( name-lbl, name-lbl-x, y-pos, option-size, darkgray)

    val input-pos = Rectangle( name-input-x.float32, y-pos.float32, max-name-width.float32, option-size.float32)
    guiTextBox( input-pos, name, max-name-length, active )

  val total-height = (num-humans + num-cpus) * (option-size + exterior-padding)
  val center-y-offset = total-height / 2

  fun collect-player-info-r( player-names : list<string>, text-box-states : list<bool> )
    if windowShouldClose() then exit()
    else
      clearBackground( raywhite )
      beginDrawing()

      val num-players = num-humans + num-cpus
      val base-y = center-y - center-y-offset
      val y-positions = list(0, num-players - 1).map( fn(x){ center-y + x * (option-size + exterior-padding)})

      val new-name-res = player-names.zip( y-positions ).map-indexed( fn( i, (n,p) ){ 
        val active = match text-box-states[i]
          Just( a ) -> a

        human-info( p, n, active )
      })

      val text-box-res = new-name-res.map( fn( (_,c) ){ c })
      val new-text-box-states = text-box-states.zip( text-box-res ).map( fn( (x,y) ){ 
        if x == y then False else True
       })

      val new-names = new-name-res.map( fn( (n,_) ){ n })

      val next = next-btn()

      endDrawing()

      if next then
        val player-types = list(1,num-humans).map( fn(_){ Human } ) ++ list(1,num-cpus).map( fn(_){ Cpu(cpu-player/Random ) } )
        player-names.zip( player-types ).map( fn( (n,t) ){ PlayerInitInfo( n, t ) })
      else
        collect-player-info-r( new-names, new-text-box-states )

  val initial-names = ["Alice", "Bob", "Charlie", "Diane"].take( num-humans + num-cpus )
  val initial-text-box-states = initial-names.map( fn(_){ False })
  collect-player-info-r( initial-names, initial-text-box-states )

fun get-player-counts( gui-state : guiState ) : <raylib-io, guiExit> (int, int)
  val title-size = 100
  val option-size = 60
  val adjust-btn-size = option-size

  val title-str = "Economancy"
  val human-players-str = "Number of human players: "
  val cpu-players-str = "Number of CPU players: "

  val padding = 25

  val center-x = windowWidth / 2
  val center-y = windowHeight / 2

  val total-height = [title-size,padding,option-size,padding,option-size].sum
  val center-y-offset = total-height / 2

  val title-y = center-y - center-y-offset
  val human-players-y = title-y + title-size + padding
  val cpu-players-y = human-players-y + option-size + padding

  val title-x = center-text( center-x, title-str, title-size )

  val max-num-string-width = measureText("4", option-size)

  val human-str-width = measureText(human-players-str, option-size)
  val human-players-width = [human-str-width, padding, adjust-btn-size, padding, max-num-string-width, padding, adjust-btn-size].sum
  val human-players-center-x-offset = human-players-width / 2

  val human-players-x = center-x - human-players-center-x-offset

  val human-adj-down-x = human-players-x + human-str-width + padding
  val human-adj-down-pos = Rectangle( float32( human-adj-down-x ),
                                      float32( human-players-y ),
                                      float32( adjust-btn-size ),
                                      float32( adjust-btn-size ))

  val human-num-x = human-adj-down-x + adjust-btn-size + padding

  val human-adj-up-x = human-num-x + max-num-string-width + padding
  val human-adj-up-pos = Rectangle( float32( human-adj-up-x ),
                                    float32( human-players-y ),
                                    float32( adjust-btn-size ),
                                    float32( adjust-btn-size ))

  val cpu-str-width = measureText(cpu-players-str, option-size)
  val cpu-players-width = [cpu-str-width, padding, adjust-btn-size, padding, max-num-string-width, padding, adjust-btn-size].sum
  val cpu-players-center-x-offset = cpu-players-width / 2

  val cpu-players-x = center-x - cpu-players-center-x-offset

  val cpu-adj-down-x = cpu-players-x + cpu-str-width + padding
  val cpu-adj-down-pos = Rectangle( float32( cpu-adj-down-x ),
                                    float32( cpu-players-y ),
                                    float32( adjust-btn-size ),
                                    float32( adjust-btn-size ))

  val cpu-num-x = cpu-adj-down-x + adjust-btn-size + padding

  val cpu-adj-up-x = cpu-num-x + max-num-string-width + padding
  val cpu-adj-up-pos = Rectangle( float32( cpu-adj-up-x ),
                                  float32( cpu-players-y ),
                                  float32( adjust-btn-size ),
                                  float32( adjust-btn-size ))

  fun get-player-counts-r( num-humans : int, num-cpus : int )
    if windowShouldClose() then exit()
    else
      clearBackground( raywhite )
      beginDrawing()

      drawText( title-str, title-x, title-y, title-size, darkgray)

      drawText( human-players-str, human-players-x, human-players-y, option-size, darkgray)
      val adj-human-down = guiButton( human-adj-down-pos, "-" )
      drawText( num-humans.show, human-num-x, human-players-y, option-size, darkgray)
      val adj-human-up = guiButton( human-adj-up-pos, "+" )

      drawText( cpu-players-str, cpu-players-x, cpu-players-y, option-size, darkgray)
      val adj-cpu-down = guiButton( cpu-adj-down-pos, "-" )
      drawText( num-cpus.show, cpu-num-x, cpu-players-y, option-size, darkgray)
      val adj-cpu-up = guiButton( cpu-adj-up-pos, "+" )

      val curr-num-players = num-humans + num-cpus

      val new-num-humans =
        if adj-human-down && curr-num-players > 2 then num-humans - 1
        else if adj-human-up && curr-num-players < 4 then num-humans + 1
        else num-humans

      val new-num-cpus =
        if adj-cpu-down && curr-num-players > 2 then num-cpus - 1
        else if adj-cpu-up && curr-num-players < 4 then num-cpus + 1
        else num-cpus

      val next = next-btn()

      endDrawing()

      if next then (num-humans, num-cpus)
      else
        get-player-counts-r( new-num-humans, new-num-cpus )

  get-player-counts-r( 1, 1 )

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
                  possible-cards : list<(cardType,int)>,
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

  val possible-maybe = possible-cards[card-idx]
  val card-ty = match possible-maybe
    Just( (c,_) ) -> c
    Nothing ->
      println("Uh oh")
      throw("uh oh")
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

fun hover-card( gui-state : guiState, bounds : list<cardBounds> ) : raylib-io ()
  val x-pos = gui-state.mouse.last-x
  val y-pos = gui-state.mouse.last-y

  if gui-state.mouse.frames-since-move >= mouse-over-frames then
    val moused-over = bounds.find( fn(cb){ is-over( cb.b, x-pos, y-pos )})
    match moused-over
      Nothing -> ()
      Just( CardBounds( _, ty ) ) -> gui-state.draw-mouse-over( ty, x-pos, y-pos )
  else ()

fun show-income-results( init-gui-state : guiState, game-state : gameState, player-incomes : list<int> ) : <raylib-io, guiExit> guiState
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
      
fun get-invest( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, playerMove)
  val padding = 25

  val adjust-center-x = windowWidth / 2
  val adjust-center-y = windowHeight / 2

  val adjust-btn-width = 75
  val invest-font-size = adjust-btn-width

  val num-coins = game-state.get-player( player-name ).coins

  fun get-invest-r( prev-gui-state : guiState, curr-invest : int )
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
      val player-stacks = gui-state.draw-players( game-state.players, active-player = Just( player-name ) )
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

      if invest-clicked then (gui-state, InvestMove( curr-invest ) )
      else get-invest-r( gui-state, new-invest )

  get-invest-r( init-gui-state, 0 )

fun show-invest-results( init-gui-state : guiState, game-state : gameState, winner-name : maybe<string>, investments: list<int> ) : <raylib-io, guiExit> guiState
  fun show-invest-results-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )

      val player-incomes = investments.map( fn( invest ){ invest * -1 } )
    
      // Draw player cards
      val player-stacks = gui-state.draw-players( game-state.players, Nothing, maybe-incomes = Just( player-incomes ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      // Draw invest winner (or indicate that no one one)
      val winner-text = match winner-name
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

fun get-attack-choice( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, playerMove)
  val padding = 25

  val center-x = windowWidth / 2
  val center-y = windowHeight / 2

  val (attacker-name-str, attacker-choice) = match game-state.phase
    Attack( name, choice ) -> (name, choice)

  val choose-text = if attacker-name-str == player-name then "Choose attacker" else "Choose defender"
  val choose-font-size = 60

  val chooser-card-width = 300
  
  val choose-text-x = center-x - measureText( choose-text, choose-font-size ) / 2
  val choose-text-y = 230

  val num-cards = game-state.get-player( player-name ).cards.length
  val possible-cards = game-state.get-player( player-name ).cards.zip( list(0, num-cards - 1) ).filter( fn( (c,_) ){ 
    if attacker-name-str == player-name then c.attacks > 0
    else c.defends > 0
  } ).map( fn( (c,i) ){ (c.ty,i) })

  val btn-width = 300.0
  val btn-height = 150.0

  val btn-x : float64 = windowWidth.float64 - btn-width - 25.0

  val pass-btn-y : float64 = windowHeight.float64 - btn-height - 25.0
  val choose-btn-y : float64 = pass-btn-y - 25.0 - btn-height

  val pass-btn-pos = Rectangle( btn-x.float32, pass-btn-y.float32, btn-width.float32, btn-height.float32 )
  val choose-btn-pos = Rectangle( btn-x.float32, choose-btn-y.float32, btn-width.float32, btn-height.float32 )

  fun get-attack-choice-r( prev-gui-state : guiState, curr-card-idx : int )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )
    
      // Draw player cards
      val player-stacks = gui-state.draw-players( game-state.players, active-player = Just( player-name ), attacker = Just( attacker-name-str ), attacker-card-idx = attacker-choice )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      drawText( choose-text, choose-text-x, choose-text-y, choose-font-size, darkgray )

      val (new-card-idx, choose-clicked) = if possible-cards.length > 0 then
        val new-card-idx = gui-state.card-chooser( possible-cards,
                                                  curr-card-idx,
                                                  center-x,
                                                  center-y - 15,
                                                  chooser-card-width )

        val choose-clicked = guiButton( choose-btn-pos, "Choose" )
        (new-card-idx, choose-clicked)
      else (-1, False)

      val pass-clicked = guiButton( pass-btn-pos, "Pass" )

      gui-state.hover-card( stack-bounds )

      endDrawing()

      val new-gui-state = gui-state

      if pass-clicked then (new-gui-state, game/types/Pass)
      else if choose-clicked then
        val (_, idx) = possible-cards[curr-card-idx].gui/unjust( kk-line )
        (new-gui-state, AttackMove( idx ))
      else get-attack-choice-r( new-gui-state, new-card-idx )

  get-attack-choice-r( init-gui-state, 0 )

fun show-attack-results( init-gui-state : guiState, game-state : gameState, attack-results : list<attackResult>) : <raylib-io, guiExit> guiState
  fun draw-result( gui-state : guiState, result : attackResult, pos-x : int, pos-y : int, card-tgt-width : int )
    val name-size = 44
    val player-text-width = measureText( result.player-name, name-size )

    val padding = 10
    
    val card-scaled = gui-state.scale-card( card-tgt-width )

    val total-height = [name-size, padding, card-scaled.height].sum
    val center-y-offset = total-height / 2

    val name-x = pos-x + card-tgt-width / 2 - player-text-width / 2
    val name-y = pos-y - center-y-offset

    val card-y = name-y + padding + name-size

    drawText( result.player-name, name-x, name-y, name-size, darkgray )

    // Defeated players never have a card.
    val bounds = match result.card
      Just( card-ty ) ->
        val draw-color = if result.outcome.is-cardFainted then red else white
        Just( CardBounds( gui-state.draw-card( card-ty, pos-x, card-y, card-scaled.width, draw-color ), card-ty ) )
      Nothing -> Nothing
    
    if result.outcome.is-playerDefeated then
      val defeated-size = name-size - 5
      val defeated-x =  pos-x + (card-tgt-width / 2) - (measureText("DEFEATED", defeated-size) / 2)
      drawText( "DEFEATED", defeated-x, card-y, defeated-size, red )
    else ()

    bounds


  fun show-attack-results-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      // Draw phase and day
      draw-phase( game-state.phase )
      draw-day( game-state.day )

      val player-stacks = gui-state.draw-players( game-state.players, Nothing )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      val choice-width = 250
      val center-y = windowHeight / 2

      val padding = 10

      val center-x = windowWidth / 2

      val vs-x = choice-width + padding
      val vs-size = 75
      val vs-width = measureText( "VS", vs-size )

      val defenders = attack-results.filter( fn(r){ r.role.is-defender } )

      val defenders-x = vs-x + vs-width + padding
      val defender-xs = defenders.map-indexed( fn( i, _ ){ defenders-x + (choice-width + padding) * i })

      val x-center-offset = (defender-xs.maximum + choice-width) / 2

      val attacker-result = attack-results.find( fn(r){ r.role.is-attacker }).gui/unjust( kk-line )
      val attacker-bounds = draw-result( gui-state, attacker-result, center-x - x-center-offset, center-y, choice-width )

      val vs-y = center-y - vs-size / 2
      drawText("VS", center-x - x-center-offset + vs-x, vs-y, vs-size, darkgray)

      val defenders-pos = defender-xs.zip( defenders )

      val defender-bounds = defenders-pos.map( fn( (x, o) ) {
        draw-result( gui-state, o, center-x - x-center-offset + x , center-y, choice-width )
      })

      val next-clicked = next-btn()

      val card-bounds-maybe = [attacker-bounds] ++ defender-bounds
      val card-bounds = card-bounds-maybe.filter( fn(x){ x.is-just }).map( fn(x){ x.gui/unjust( kk-line ) } ) ++ stack-bounds
      gui-state.hover-card( card-bounds )

      endDrawing()

      if next-clicked then gui-state
      else show-attack-results-r( gui-state )

  show-attack-results-r( init-gui-state )

fun get-buy-choice( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, playerMove)
  if game-state.get-player( player-name ).buys == 0 then (init-gui-state, Pass)
  else
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

    fun get-buy-choice-r( prev-gui-state : guiState, curr-card : maybe<cardType> )
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

        val card-scaled = gui-state.scale-card( 160 )

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
                Just( ty ) -> if ty == card then yellow else white

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

        val player-coins = game-state.players.find( fn(p){ p.name == player-name } ).unjust.coins

        val new-card = if isMouseButtonPressed( mouseButtonLeft ) then
          val clicked-card = stock-bounds.find( fn(cb){ is-over( cb.b, gui-state.mouse.last-x, gui-state.mouse.last-y ) })
          match clicked-card
            Nothing -> curr-card
            Just( CardBounds(_, ty ) ) ->
              if game-state.store.get-stock-count( ty ) > 0 && ty.get-price <= player-coins then
                Just( ty )
              else curr-card
        else curr-card

        val choose-clicked = guiButton( choose-btn-pos, "Choose" )
        val pass-clicked = guiButton( pass-btn-pos, "Pass" )

        val all-bounds = stack-bounds ++ stock-bounds
        gui-state.hover-card( all-bounds )

        endDrawing()

        val new-gui-state = gui-state

        // TODO: Don't allow clicking choose if no card selected
        // TODO: Don't allow choosing cards with 0 stock.

        if pass-clicked then (gui-state, game/types/Pass)
        else if choose-clicked then 
          match curr-card
            Nothing -> get-buy-choice-r( gui-state, curr-card )
            Just( ty ) -> (new-gui-state, BuyMove( ty ))
        else get-buy-choice-r( gui-state, new-card )

    get-buy-choice-r( init-gui-state, Nothing )

fun show-buy-results( init-gui-state : guiState, game-state : gameState, cards : list<maybe<cardType>>, conflicts : list<bool>, amts: list<int> ) : <raylib-io, guiExit> guiState
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
      val player-incomes = amts.map( fn(x){ x * -1 })
      val player-stacks = gui-state.draw-players( game-state.players, Nothing, Just( player-incomes ) )
      val stack-bounds = player-stacks.flatmap( fn(s){ s.bounds })

      // Draw purchased cards.
      val scaled = gui-state.scale-card( 200 )
      val padding = 15

      val offsets = list(0,game-state.players.length - 1).map( fn(x){ x * (scaled.width + padding)})
      val total-width = offsets.maximum + scaled.width
      val center-x-offset = total-width / 2

      val name-size = 44
      val height = name-size + padding + scaled.height
      val center-y-offset = height / 2

      val center-x = windowWidth / 2
      val center-y = windowHeight / 2

      offsets.map-indexed( fn(i, x){
        val name-y = center-y - center-y-offset
        val name = game-state.players[i].gui/unjust( kk-line ).name
        val name-width = measureText( name, name-size )
        val name-x = center-x - center-x-offset + x + scaled.width / 2 - name-width / 2
        drawText( name, name-x, name-y, name-size, darkgray )

        val highlight-color = if conflicts[i].gui/unjust( kk-line ) then red else white

        val card-y = name-y + name-size + padding
        val card-x = center-x - center-x-offset + x
        val card = cards[i].gui/unjust( kk-line )
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

fun show-victory( init-gui-state : guiState, game-state : gameState ) : <raylib-io, guiExit> guiState
  fun show-victory-r( prev-gui-state : guiState )
    if windowShouldClose() then exit()
    else
      val gui-state = prev-gui-state.update-mouse()

      clearBackground( raywhite )
      beginDrawing()

      gui-state.draw-players( game-state.players )

      val victor-size = 75
      val center-x = windowWidth / 2
      val center-y = windowHeight / 2

      val victory-text = "Victory!"

      val center-x-offset = measureText( victory-text, victor-size ) / 2
      val center-y-offset = victor-size / 2

      drawText(victory-text, center-x - center-x-offset, center-y - center-y-offset, victor-size, darkgray)

      endDrawing()

      show-victory-r( gui-state )

  show-victory-r( init-gui-state )

// TODO: Do we need to return the gui state from this function? I think we just throw it away between phases.
pub fun get-move( gui-state : guiState, game-state : gameState, player-idx : int ) : <raylib-io,guiExit> (guiState, playerMove)
  if game-state.players[player-idx].unjust.status.is-defeated then (gui-state, Pass)
  else
    val player-name = game-state.players[player-idx].unjust.name

    match game-state.phase
      Invest -> gui-state.get-invest( game-state, player-name )
      Buy -> gui-state.get-buy-choice( game-state, player-name )
      Attack -> gui-state.get-attack-choice( game-state, player-name )

pub fun show-phase-results( gui-state : guiState, game-state : gameState, phase-result : phaseResult ) : <raylib-io,guiExit> guiState
  match phase-result
    IncomePhaseResult( incomes ) -> gui-state.show-income-results( game-state, incomes )
    InvestPhaseResult( winner-name, investments ) -> gui-state.show-invest-results( game-state, winner-name, investments )
    AttackPhaseResult( results ) -> gui-state.show-attack-results( game-state, results )
    BuyPhaseResult( cards, conflicts, amts ) -> gui-state.show-buy-results( game-state, cards, conflicts, amts )
    VictoryPhase -> gui-state.show-victory( game-state )