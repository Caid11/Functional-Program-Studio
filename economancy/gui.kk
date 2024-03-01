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
val windowCenter = GuiPosition( windowWidth / 2, windowHeight / 2 )

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

// NOTE: Hard-coding this avoids having to pass a guiState to do layout calculations
// This is height / width
val card-aspect-ratio = 1.36
  
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

val phase-day-size = 60

fun phase-element( game-phase : phase ) : raylib-io guiElement
  val info = Text( phase-day-size, game-phase.show, darkgray )
  val phase-x = windowWidth - info.width - 25
  GuiElement( "phase", GuiPosition( phase-x, 25 ), info )

fun day-element( game-day : day ) : raylib-io guiElement
  val day-text = "DAY " ++ game-day.show
  GuiElement( "day", GuiPosition( 25, 25 ), Text( phase-day-size, day-text, darkgray ) )

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

fun get-player-card-colors( game-state : gameState,
                            player : player )
  val (is-attacker, attack-idx) = match game-state.phase
    Attack( attacker, attacker-choice ) -> 
      val is-attacker = attacker == player.name

      val attack-idx = match attacker-choice
        Nothing -> -1
        Just( i ) -> if is-attacker then i else -1

      (is-attacker, attack-idx)

    _ -> (False, -1)
  
  fun is-tapped( card )
    match game-state.phase
      Attack( _, _ ) -> if is-attacker then card.attacks == 0 else card.defends == 0
      _ -> False

  player.cards.map-indexed( fn( i, c ){
    if i == attack-idx then red
    else
      if is-tapped( c ) then gray else white
  })

fun get-player-elements( game-state : gameState,
                         player : player,
                         loc : playerLoc,
                         is-active : bool,
                         coin-change : int )
  fun elem( id, e )
    GuiElement( "player-" ++ player.show ++ "-" ++ id, GuiPosition(0,0), e )

  val player-font-size = 36

  val name-color = if is-active then green else darkgray
  val player-name = elem( "name", Text( player-font-size, player.name, name-color ) )

  val rest-elements = if player.status.is-defeated then
    [[elem( "defeated", Text( player-font-size, "DEFEATED", red))]]
  else
      val card-tys = player.cards.map( fn(c){ c.ty })
      val card-colors = get-player-card-colors( game-state, player )
      val card-stack = elem( "cards", CardStack( 100, 0.3, card-tys, card-colors ) )

      val curr-coins = elem( "coins", Text(player-font-size, "Coins: " ++ player.coins.show, darkgray ) )
      val coin-elems = if coin-change == 0 then
        [curr-coins]
      else
        val (changed-color, changed-sign) = if coin-change > 0 then (green, "+") else (red, "")
        val changed-coins = elem( "coins-changed", Text( player-font-size, "(" ++ changed-sign ++ coin-change.show ++ ")", changed-color ))
        [curr-coins, changed-coins]
      [[card-stack], coin-elems]

  // TODO: Switch this to return guiPosition after refactor is complete
  val (pos-x, pos-y) = loc.get-player-coords
  val pos = GuiPosition( pos-x, pos-y )
  center-on-point(pos, [[player-name]] ++ rest-elements)
    
fun get-players-elements( game-state : gameState,
                          active-player : maybe<string> = Nothing,
                          maybe-coin-changes : maybe<list<int>> = Nothing )
  val locs = [Bottom, Top, Left, Right]
  val is-active = match active-player
    Nothing -> game-state.players.map( fn(_){ False })
    Just( n ) -> game-state.players.map( fn(p){ p.name == n })
  val coin-changes = match maybe-coin-changes
    Just( c ) -> c
    Nothing -> game-state.players.map( fn(_){ 0 } )

  game-state.players.zip( locs ).zip( is-active ).zip( coin-changes ).map( fn( (((p,l),a), c) ){
    get-player-elements( game-state, p, l, a, c )
  }).flatmap( fn(e){ e })

effect guiExit
  ctl exit() : a

pub fun get-player-info( gui-state : guiState ) : <raylib-io, guiExit> list<playerInitInfo>
  val (num-human-players, num-cpu-players) = gui-state.get-player-counts()
  gui-state.collect-player-info( num-human-players, num-cpu-players )

fun collect-player-info( gui-state : guiState, num-humans : int, num-cpus : int ) : <raylib-io, guiExit> list<playerInitInfo>
  val option-size = 80

  val max-name-length = 10
  val max-name-width = measureText( list(1,max-name-length).map( fn(_){ 'X' } ).string, option-size )

  val input-size = Size2D( max-name-width, option-size)
  val btn-size = Size2D( option-size, option-size)

  fun get-player-info-elems( num : int, ty : playerType, name : string, is-active : bool )
    val name-elem = GuiElement( "player-name-input-" ++ num.show, GuiPosition(0,0),
                                TextInput( input-size, "Name: ", name, max-name-length, is-active ) )
    val strategy-elems = match ty
      Human -> []
      Cpu( strategy ) -> [
        GuiElement( "player-" ++ num.show ++ "-strategy-left", GuiPosition(0,0), Button(btn-size, "<")),
        GuiElement( "player-" ++ num.show ++ "-strategy", GuiPosition(0,0), Text(option-size, strategy.show, darkgray)),
        GuiElement( "player-" ++ num.show ++ "-strategy-right", GuiPosition(0,0), Button(btn-size, ">")),
      ]
    [[name-elem] ++ strategy-elems]

  val next-btn-elem = next-btn-element()
  
  fun collect-player-info-r( prev-gui-state : guiState, player-names : list<string>, player-tys : list<playerType>, text-box-states : list<bool> )
    val gui-elements = player-names.zip( player-tys ).zip( text-box-states ).map-indexed( fn( i, ((name, ty), tbox-state)){
      get-player-info-elems( i, ty, name, tbox-state )
    }).flatmap( fn(x){ x })

    val centered = center-on-point( windowCenter, gui-elements )
    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( centered ++ [next-btn-elem] )

    val new-names = draw-results.filter-map( fn(r){
      match r
        NoChange( GuiElement( _, _, TextInput(_, _, text, _, _))) -> Just( text )
        ActiveToggle( GuiElement( _, _, TextInput(_, _, text, _, _)), _ ) -> Just( text )
        TextChanged( GuiElement( _, _, TextInput(_, _, _, _, _)), text ) -> Just( text )
        _ -> Nothing
    })
    val new-actives = draw-results.filter-map( fn(r){
      match r
        NoChange( GuiElement( _, _, TextInput(_, _, text, _, is-active))) -> Just( is-active )
        ActiveToggle( GuiElement( _, _, TextInput(_, _, text, _, _)), is-active ) -> Just( is-active )
        TextChanged( GuiElement( _, _, TextInput(_, _, text, _, is-active)), _ ) -> Just( is-active )
        _ -> Nothing
    })

    val strategies = [cpu-player/Pass, cpu-player/Random, cpu-player/Defensive]

    fun prev-strategy( s : strategy)
      val prev-idx = strategies.index-of( fn(strat){ strat == s } )
      val new-idx =
        if prev-idx <= 0 then strategies.length - 1
        else prev-idx - 1
      strategies[new-idx].unjust

    fun next-strategy( s : strategy )
      val prev-idx = strategies.index-of( fn(strat){ strat == s } )
      val new-idx =
        if prev-idx == strategies.length - 1 then 0
        else prev-idx + 1
      strategies[new-idx].unjust

    val new-tys = player-tys.map-indexed( fn(i, ty){
      match ty
        Human -> Human
        Cpu( s ) ->
          if draw-results.clicked( "player-" ++ i.show ++ "-strategy-left" ) then Cpu( prev-strategy( s ) )
          else if draw-results.clicked( "player-" ++ i.show ++ "-strategy-right" ) then Cpu( next-strategy( s ) )
          else ty 
    })

    if draw-results.clicked( next-btn-elem.id ) then
      new-names.zip( new-tys ).map( fn( (n,t) ){ PlayerInitInfo(n, t)})
    else
      collect-player-info-r( gui-state, new-names, new-tys, new-actives)


  val initial-names = ["Alice", "Bob", "Charlie", "Diane"].take( num-humans + num-cpus )
  val initial-tys = list(1, num-humans).map( fn(_){ Human }) ++ list(1,num-cpus).map( fn(_){ Cpu( cpu-player/Pass )})
  val initial-text-box-states = initial-names.map( fn(_){ False })
  collect-player-info-r( gui-state, initial-names, initial-tys, initial-text-box-states )

fun get-player-counts( gui-state : guiState ) : <raylib-io, guiExit> (int, int)
  fun get-elements( curr-humans : int, curr-cpus : int)
    val title-elem = GuiElement( "title", GuiPosition(0,0), Text(150, "Economancy", darkgray) )

    val option-size = 80
    val adj-btn-size = Size2D( option-size, option-size )

    val human-players-elements = [
      GuiElement( "human-players-lbl", GuiPosition(0,0), Text(option-size, "Number of human players:", darkgray) ),
      GuiElement( "human-players-down", GuiPosition(0,0), Button(adj-btn-size, "-") ),
      GuiElement( "human-players-curr", GuiPosition(0,0), Text(option-size, curr-humans.show, darkgray) ),
      GuiElement( "human-players-up", GuiPosition(0,0), Button(adj-btn-size, "+") ),
    ]

    val cpu-players-elements = [
      GuiElement( "cpu-players-lbl", GuiPosition(0,0), Text(option-size, "Number of cpu players:", darkgray) ),
      GuiElement( "cpu-players-down", GuiPosition(0,0), Button(adj-btn-size, "-") ),
      GuiElement( "cpu-players-curr", GuiPosition(0,0), Text(option-size, curr-cpus.show, darkgray) ),
      GuiElement( "cpu-players-up", GuiPosition(0,0), Button(adj-btn-size, "+") ),
    ]

    center-on-point( windowCenter, [
      [title-elem],
      human-players-elements,
      cpu-players-elements
    ])

  val next-btn-elem = next-btn-element()

  fun get-player-counts-r( prev-gui-state : guiState, num-humans : int, num-cpus : int )
    val gui-elements = get-elements( num-humans, num-cpus ) ++ [next-btn-elem]
    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( gui-elements )

    val curr-num-players = num-humans + num-cpus

    val new-num-humans =
      if draw-results.clicked( "human-players-down") && curr-num-players > 2 && num-humans > 0 then num-humans - 1
      else if draw-results.clicked( "human-players-up") && curr-num-players < 4 && num-humans < 4 then num-humans + 1
      else num-humans

    val new-num-cpus =
      if draw-results.clicked( "cpu-players-down") && curr-num-players > 2 && num-cpus > 0 then num-cpus - 1
      else if draw-results.clicked( "cpu-players-up") && curr-num-players < 4 && num-cpus < 4 then num-cpus + 1
      else num-cpus

    if draw-results.clicked( next-btn-elem.id ) then (num-humans, num-cpus)
    else get-player-counts-r( new-gui-state, new-num-humans, new-num-cpus )
  
  get-player-counts-r( gui-state, 1, 1 )

fun is-over( r : bounds, x-pos : int, y-pos : int ) : <> bool
  val left = r.x
  val right = r.x + r.width
  val top = r.y
  val bottom = r.y + r.height

  x-pos >= left && x-pos <= right && y-pos >= top && y-pos <= bottom

fun next-btn-element() : raylib-io guiElement
  val size = Size2D( 300, 200 )
  val btn = Button( size, "Next" )
  val pos = GuiPosition( windowWidth - btn.width - 25, windowHeight - btn.height - 25 )

  GuiElement( "next-btn", pos, btn )

fun draw-mouse-over( gui-state : guiState, card : cardType, x-pos : int, y-pos : int ) : raylib-io ()
  val card-scaled = gui-state.scale-card( 300 )

  val card-x = if x-pos > windowWidth / 2 then x-pos - card-scaled.width else x-pos
  val card-y = if y-pos > windowHeight / 2 then y-pos - card-scaled.height else y-pos

  gui-state.draw-card( card, card-x, card-y, card-scaled.width, white)
  ()

fun show-income-results( init-gui-state : guiState, game-state : gameState, player-incomes : list<int> ) : <raylib-io, guiExit> guiState
  val next-btn-elem = next-btn-element()
  val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]
  val player-elements = get-players-elements( game-state, maybe-coin-changes = Just( player-incomes ) )

  val all-elements = [next-btn-elem] ++ phase-day-elements ++ player-elements

  fun show-income-results-r( prev-gui-state : guiState )
    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-elements )

    if draw-results.clicked( next-btn-elem.id ) then new-gui-state
    else
      show-income-results-r( new-gui-state )
  
  show-income-results-r( init-gui-state )

struct size2D
  x : int
  y : int

struct guiPosition
  x : int
  y : int

val text-input-padding = 10

type guiElementInfo
  Text( size : int, text : string, col : color )
  Button( size : size2D, text : string )
  TextInput( size : size2D, label : string, text : string, max-len : int, is-active : bool )
  Card( width : int, ty : cardType, tint-color : color )
  LabeledCard( card-width : int, ty : maybe<cardType>, tint-color : color, label : string, lable-size : int )
  CardStack( card-width : int, overlap : float64, tys : list<cardType>, tint-colors : list<color> )

struct guiElement
  id : string
  pos : guiPosition
  info : guiElementInfo

val labeled-card-padding = 10

fun height( info : guiElementInfo ) : int
  match info
    Text( size, _, _ ) -> size
    Button( size, _ ) -> size.y
    TextInput( size, _, _, _, _ ) -> size.y
    Card( width, _, _ ) -> int(width.float64 * card-aspect-ratio)
    LabeledCard( width, _, _, _, label-size ) ->
      int(width.float64 * card-aspect-ratio) + labeled-card-padding + label-size
    CardStack( card-width, _, _, _ ) -> int(card-width.float64 * card-aspect-ratio)

fun width( info : guiElementInfo ) : raylib-io int
  match info
    Text( size, text, _ ) -> measureText( text, size )
    Button( size, _ ) -> size.x
    TextInput( size, label, _, _, _ ) -> measureText( label, size.y ) + text-input-padding +  size.x
    Card( width, _, _ ) -> width
    LabeledCard( width, _, _ ) -> width
    CardStack( card-width, overlap, tys, _ ) ->
      val overlap-amt = int(card-width.float64 * overlap)
      card-width + overlap-amt * (tys.length - 1)

fun rect( pos : guiPosition, size : size2D) : rectangle
  Rectangle( pos.x.float32, pos.y.float32, size.x.float32, size.y.float32 )

type guiDrawResult
  NoChange( element : guiElement )
  Clicked( element : guiElement )
  ActiveToggle( element : guiElement, is-active : bool )
  TextChanged( element : guiElement, new-text : string )

fun clicked( results : list<guiDrawResult>, clicked-id : string )
  val clicked = results.find( fn(e){ 
    match e
      Clicked( element ) -> element.guiElement/id == clicked-id
      _ -> False
  })

  clicked.is-just

val mouse-over-frames = int(60.0 * 0.5)

fun draw-gui( init-gui-state : guiState, elements : list<guiElement> ) : <raylib-io, guiExit> (guiState, list<guiDrawResult>)
  if windowShouldClose() then exit()
  else
    clearBackground( raywhite )
    beginDrawing()

    val gui-state = init-gui-state.update-mouse()

    val mouse-pressed = isMouseButtonPressed( mouseButtonLeft )

    val draw-results = elements.map( fn(e){
      match e
        GuiElement( _, pos, Text( size, text, col ) ) ->
          drawText( text, pos.x, pos.y, size, col )
          NoChange( e )

        GuiElement( _, pos, Button( size, text ) ) ->
          val is-clicked = guiButton( rect( pos, size ), text )
          if is-clicked then Clicked( e ) else NoChange( e )

        GuiElement( _, pos, TextInput( size, label, text, max-len, is-active ) ) ->
          // Draw text box label.
          drawText( label, pos.x, pos.y, size.y, darkgray )
          val x-offset = measureText( label, size.y ) + text-input-padding

          // Text boxes are a little weird. They return true if they were
          // clicked, enter was pressed while they were active, or if the user
          // clicks outside of the input while the input is active.
          //
          // For our purposes, we can simply XOR the current active state with
          // whether or not an event occured.
          val textbox-pos = rect( GuiPosition( pos.x + x-offset, pos.y ), size )
          val (new-text, textbox-evt) = guiTextBox( textbox-pos, text, max-len, is-active )
          val new-active = textbox-evt != is-active
          
          if new-active != is-active then ActiveToggle( e, new-active )
          else if new-text != text then TextChanged( e, new-text )
          else NoChange( e )

        GuiElement( _, pos, Card( width, ty, tint-color ) ) ->
          val b = gui-state.draw-card( ty, pos.x, pos.y, width, tint-color )

          if mouse-pressed && is-over( b, gui-state.mouse.last-x, gui-state.mouse.last-y ) then Clicked( e )
          else NoChange( e )

        GuiElement( _, pos, LabeledCard( width, maybe-ty, tint-color, label, label-size ) ) ->
          // Center text under card.
          val label-pos = GuiPosition(
            pos.x + (width - measureText(label, label-size)) / 2,
            pos.y + int(width.float64 * card-aspect-ratio) + labeled-card-padding
          )
          drawText( label, label-pos.x, label-pos.y, label-size, darkgray )

          match maybe-ty
            Nothing -> NoChange( e )
            Just( ty ) ->
              val b = gui-state.draw-card( ty, pos.x, pos.y, width, tint-color )
              if mouse-pressed && is-over( b, gui-state.mouse.last-x, gui-state.mouse.last-y ) then Clicked( e )
              else NoChange( e )

        GuiElement( _, pos, CardStack( card-width, overlap, tys, tint-colors ) ) ->
          val overlap-amt = int(card-width.float64 * overlap)
          val x-offsets = tys.map-indexed( fn( i, _ ){ i * overlap-amt })
          val bounds = tys.zip( tint-colors ).map-indexed( fn( i, (ty,col) ){
            val x-pos = pos.x + i * overlap-amt
            gui-state.draw-card( ty, x-pos, pos.y, card-width, col )
          } )

          if mouse-pressed && bounds.any( fn( b ){ is-over( b, gui-state.mouse.last-x, gui-state.mouse.last-y ) }) then Clicked( e )
          else NoChange( e )
    })

    // Draw hovered card, if applicable
    if gui-state.mouse.frames-since-move >= mouse-over-frames then
      elements.find( fn(e){
        match e
          GuiElement( _, pos, Card( card-width, ty, _ ) ) ->
            val scaled = gui-state.scale-card( card-width )
            val b = Bounds( pos.x, pos.y, scaled.width, scaled.height )

            if is-over( b, gui-state.mouse.last-x, gui-state.mouse.last-y ) then
              gui-state.draw-mouse-over( ty, gui-state.mouse.last-x, gui-state.mouse.last-y )
              True
            else False

          GuiElement( _, pos, LabeledCard( card-width, maybe-ty, _, _, _ ) ) ->
            match maybe-ty
              Just( ty ) ->
                val scaled = gui-state.scale-card( card-width )
                val b = Bounds( pos.x, pos.y, scaled.width, scaled.height )

                if is-over( b, gui-state.mouse.last-x, gui-state.mouse.last-y ) then
                  gui-state.draw-mouse-over( ty, gui-state.mouse.last-x, gui-state.mouse.last-y )
                  True
                else False
              Nothing -> False

          GuiElement( _, pos, CardStack( card-width, overlap, tys ) ) ->
            val scaled = gui-state.scale-card( card-width )
            val overlap-amt = int(card-width.float64 * overlap)
            val tys-and-bounds = tys.map-indexed( fn( i, ty ){
              val x-pos = pos.x + i * overlap-amt
              (ty, Bounds( x-pos, pos.y, scaled.width, scaled.height ) )
            })

            tys-and-bounds.reverse.any( fn( (ty,b) ){
              if is-over( b, gui-state.mouse.last-x, gui-state.mouse.last-y ) then
                gui-state.draw-mouse-over( ty, gui-state.mouse.last-x, gui-state.mouse.last-y )
                True
              else False
            })
          _ -> False
      })

      ()
    else ()

    endDrawing()

    (gui-state, draw-results)

alias guiRow = list<guiElement>

val row-padding = 10

fun center-rows( pos : guiPosition, y-pos : int, rows : list<guiRow>, centered-rows : list<guiRow> = [] )
  match rows
    Nil -> centered-rows
    Cons( r, rs ) ->
      val row-width = r.map( fn(e){ e.info.width }).sum + (r.length - 1) * row-padding
      val center-row-x-offset = row-width / 2
      val base-x = pos.x - center-row-x-offset

      val max-height = r.map( fn(e){ e.info.height } ).maximum

      fun center-elems( e : list<guiElement>, curr-x, centered-elems = [] )
        match e
          Nil -> centered-elems
          Cons( x, xs ) -> 
            val height-diff = max-height - x.info.height
            val final-y = y-pos + height-diff / 2

            val next-x = curr-x + x.info.width + row-padding

            center-elems( xs, next-x, centered-elems ++ [x( pos = GuiPosition( curr-x, final-y ) )] )

      center-rows( pos, y-pos + max-height + row-padding, rs, centered-rows ++ [center-elems( r, base-x )] )

fun center-on-point( pos : guiPosition, rows : list<guiRow>) : raylib-io list<guiElement>
  // Calculate y-offset to center all rows vertically
  val max-heights = rows.map( fn( r ){
    r.map( fn( e ){ e.info.height } ).maximum
  } )
  val total-height = max-heights.sum + row-padding * (max-heights.length - 1)
  val center-all-y-offset = total-height / 2
  val base-y = pos.y - center-all-y-offset

  center-rows( pos, base-y, rows ).flatmap( fn(x){ x } )
 
fun get-invest( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, playerMove)
  val adjust-btn-width = 75
  val invest-font-size = adjust-btn-width

  val num-coins = game-state.get-player( player-name ).coins

  val adjust-button-size = Size2D( 75, 75 )
  val invest-button-size = Size2D( measureText("Invest", 75) + 50, 75 )

  fun get-invest-elements( curr-invest : int )
    center-on-point( windowCenter, [
      [ 
        GuiElement( "invest-down", GuiPosition(0,0), Button( adjust-button-size, "-" ) ) ,
        GuiElement( "invest-lbl", GuiPosition(0,0), Text( invest-font-size, curr-invest.show, darkgray ) ),
        GuiElement( "invest-up", GuiPosition(0,0), Button( adjust-button-size, "+" ) ),
      ],

      [ GuiElement( "invest-btn", GuiPosition(0,0), Button( invest-button-size, "Invest" ) ) ],
    ])

  val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]
  val player-elements = get-players-elements( game-state, Just( player-name ) )

  fun get-invest-r( prev-gui-state : guiState, curr-invest : int )
    val invest-gui-elements = get-invest-elements( curr-invest )
    val all-gui-elements = phase-day-elements ++ player-elements ++ invest-gui-elements

    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-gui-elements )

    if draw-results.clicked( "invest-btn" ) then (new-gui-state, InvestMove( curr-invest ))
    else
      val new-invest = if draw-results.clicked( "invest-down" ) then
        [0, curr-invest - 1].maximum
      else if draw-results.clicked( "invest-up" ) then
        [num-coins, curr-invest + 1].minimum
      else curr-invest

      get-invest-r( new-gui-state, new-invest )

  get-invest-r( init-gui-state, 0 )

fun show-invest-results( init-gui-state : guiState, game-state : gameState, winner-name : maybe<string>, investments: list<int> ) : <raylib-io, guiExit> guiState
  val winner-str = match winner-name
    Nothing -> "No one wins"
    Just( n ) -> n ++ " wins!"
  val winner-element = center-on-point( windowCenter, [[GuiElement( "winner", GuiPosition(0,0), Text(125, winner-str, darkgray))]])

  val next-btn-elem = next-btn-element()

  val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]

  val player-coin-changes = investments.map( fn(x){ x * -1 })
  val player-elements = get-players-elements( game-state, maybe-coin-changes = Just( player-coin-changes ) )

  val all-elements = [next-btn-elem] ++ winner-element ++ phase-day-elements ++ player-elements

  fun show-invest-results-r( prev-gui-state : guiState )
    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-elements )

    if draw-results.clicked( next-btn-elem.id ) then new-gui-state
    else
      show-invest-results-r( new-gui-state )

  show-invest-results-r( init-gui-state )

fun get-attack-choice( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, playerMove)
  val is-attacker = match game-state.phase
    Attack( name, _ ) -> name == player-name

  val choose-text = if is-attacker then "Choose attacker" else "Choose defender"
  val choose-text-element = GuiElement( "choose-text", GuiPosition(0,0), Text( 60, choose-text, darkgray))

  val num-cards = game-state.get-player( player-name ).cards.length
  val possible-cards = game-state.get-player( player-name ).cards.zip( list(0, num-cards - 1) ).filter( fn( (c,_) ){ 
    if is-attacker then c.attacks > 0
    else c.defends > 0
  } ).map( fn( (c,i) ){ (c.ty,i) })

  val chooser-card-width = 300
  val chooser-btn-size = Size2D( chooser-card-width / 3, chooser-card-width / 3 )

  val chooser-left-btn = GuiElement( "choose-left", GuiPosition(0,0), Button( chooser-btn-size, "<" ))
  val chooser-right-btn = GuiElement( "choose-right", GuiPosition(0,0), Button( chooser-btn-size, ">" ))

  fun chooser-elems( curr-idx )
    val chooser-rows = match possible-cards[curr-idx]
      Just( (ty,_) ) ->
        val chooser-card  = GuiElement( "choose-card", GuiPosition(0,0), Card( chooser-card-width, ty, white ))
        [ [choose-text-element],
          [chooser-left-btn, chooser-card, chooser-right-btn] ]
      Nothing -> [ [choose-text-element] ]

    center-on-point( windowCenter, chooser-rows)

  val btn-size = Size2D( 300, 150 )
  val pass-btn = Button( btn-size, "Pass" )
  val choose-btn = Button( btn-size, "Choose" )

  val btn-x = windowWidth - btn-size.x - 25

  val pass-pos = GuiPosition( btn-x, windowHeight - btn-size.y - 25 )
  val choose-pos = GuiPosition( btn-x, pass-pos.y - btn-size.y - 25 )

  val button-elems = [
    GuiElement( "pass-btn", pass-pos, pass-btn ),
    GuiElement( "choose-btn", choose-pos, choose-btn )
  ]

  val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]
  val player-elements = get-players-elements( game-state, Just( player-name ) )

  fun get-attack-choice-r( prev-gui-state : guiState, curr-card-idx : int )
    val all-elements = chooser-elems( curr-card-idx ) ++ button-elems ++ phase-day-elements ++ player-elements

    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-elements )

    if draw-results.clicked( "pass-btn" ) then (new-gui-state, game/types/Pass)
    else if draw-results.clicked( "choose-btn") then
      match possible-cards[curr-card-idx]
        Just( (_,idx) ) -> (new-gui-state, AttackMove( idx ))
        Nothing -> (new-gui-state, game/types/Pass )
    else
      val new-card-idx = if draw-results.clicked( "choose-left" ) then
        if curr-card-idx == 0 then possible-cards.length - 1 else curr-card-idx - 1
      else if draw-results.clicked( "choose-right" )
        if curr-card-idx == possible-cards.length - 1 then 0 else curr-card-idx + 1
      else curr-card-idx

      get-attack-choice-r( new-gui-state, new-card-idx )

  get-attack-choice-r( init-gui-state, 0 )

fun show-attack-results( init-gui-state : guiState, game-state : gameState, attack-results : list<attackResult>) : <raylib-io, guiExit> guiState
  val name-size = 44
  val card-size = 250

  fun result-elem( result : attackResult )
    val cardColor = match result.outcome
      CardFainted -> red
      _ -> white

    GuiElement( "outcome-" ++ result.player-name, GuiPosition(0,0), LabeledCard( card-size, result.card, cardColor, result.player-name, name-size ))

  val attacker-elem = result-elem( attack-results.find( fn(res){ res.role.is-attacker }).unjust )
  val defender-elems = attack-results.filter( fn(res){ res.role.is-defender }).map( result-elem )
  val vs-text = GuiElement( "vs-lbl", GuiPosition(0,0), Text(75, "VS", darkgray))
  val result-elems = center-on-point( windowCenter, [[attacker-elem, vs-text] ++ defender-elems])

  val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]

  val player-incomes = attack-results.map( fn(r){ r.income })
  val player-elements = get-players-elements( game-state, Nothing, Just( player-incomes ) )

  val next-btn-elem = next-btn-element()
  
  val all-elems = result-elems ++ phase-day-elements ++ player-elements ++ [next-btn-elem]

  fun show-attack-results-r( prev-gui-state : guiState )
    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-elems )

    if draw-results.clicked( next-btn-elem.id ) then new-gui-state
    else
      show-attack-results-r( new-gui-state )

  show-attack-results-r( init-gui-state )

fun get-buy-choice( init-gui-state : guiState, game-state : gameState, player-name : string ) : <raylib-io, guiExit> (guiState, playerMove)
  val player-coins = game-state.get-player(player-name).coins
  if player-coins == 0 then (init-gui-state, Pass)
  else
    val cards-in-row = 7
    val card-width = 160
    val remaining-size = 20

    fun get-buy-elems( maybe-selected-ty : maybe<cardType>, stock : list<stock>, gui-rows = [])
      if stock.length == 0 then gui-rows
      else
        val (curr-row, rest) = stock.split( cards-in-row )
        val curr-row-elems = curr-row.map( fn(s){
          val card-color = match maybe-selected-ty
            Nothing -> white
            Just( selected-ty ) ->
              if s.stock/card == selected-ty then yellow else white

          GuiElement( "stock-" ++ s.show, GuiPosition(0,0), LabeledCard( card-width, Just( s.stock/card ), card-color, "Remaining: " ++ s.remaining.show, remaining-size))
        })

        get-buy-elems( maybe-selected-ty, rest, gui-rows ++ [curr-row-elems])

    val btn-size = Size2D( 300, 150 )
    val pass-btn = Button( btn-size, "Pass" )
    val choose-btn = Button( btn-size, "Choose" )

    val btn-x = windowWidth - btn-size.x - 25

    val pass-pos = GuiPosition( btn-x, windowHeight - btn-size.y - 25 )
    val choose-pos = GuiPosition( btn-x, pass-pos.y - btn-size.y - 25 )

    val button-elems = [
      GuiElement( "pass-btn", pass-pos, pass-btn ),
      GuiElement( "choose-btn", choose-pos, choose-btn )
    ]

    val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]
    val player-elements = get-players-elements( game-state, Just( player-name ) )

    fun get-buy-choice-r( prev-gui-state : guiState, curr-card : maybe<cardType> )
      val all-elems = center-on-point( windowCenter, get-buy-elems( curr-card, game-state.store ) ) ++ button-elems ++ phase-day-elements ++ player-elements
      val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-elems )

      if draw-results.clicked("pass-btn") then (new-gui-state, game/types/Pass)
      else if draw-results.clicked("choose-btn") then 
        match curr-card
          Nothing -> get-buy-choice-r( new-gui-state, curr-card )
          Just( ty ) -> (new-gui-state, BuyMove( ty ))
      else
        val new-card = match draw-results.find( fn(r){ r.is-clicked })
          Just( Clicked( GuiElement( id, _, LabeledCard( _, maybe-ty, _, _, _ ) )) ) -> 
            match maybe-ty
              Just( ty ) -> if get-price( ty ) <= player-coins then maybe-ty else Nothing
              _ -> maybe-ty
          _ -> curr-card

        get-buy-choice-r( new-gui-state, new-card )

    get-buy-choice-r( init-gui-state, Nothing )

fun show-buy-results( init-gui-state : guiState, game-state : gameState, cards : list<maybe<cardType>>, conflicts : list<bool>, amts: list<int> ) : <raylib-io, guiExit> guiState
  val name-size = 44
  val card-width = 200

  val player-choice-elems = center-on-point( windowCenter, [
    game-state.players.zip( cards ).zip( conflicts ).map( fn( ((player, maybe-ty), conflict) ){
      val color = if conflict then red else white
      GuiElement( "choice-" ++ player.name, GuiPosition(0,0), LabeledCard( card-width, maybe-ty, color, player.name, name-size ))
    })
  ])
  val next-btn-elem = next-btn-element()

  val phase-day-elems = [day-element( game-state.day ), phase-element( game-state.phase )]

  val player-coin-changes = amts.map( fn(x){ x * -1 })
  val player-elements = get-players-elements( game-state, maybe-coin-changes = Just( player-coin-changes ) )

  val all-elems = player-choice-elems ++ [next-btn-elem] ++ phase-day-elems ++ player-elements

  fun show-buy-results-r( prev-gui-state : guiState )
    val (new-gui-state, draw-results) = prev-gui-state.draw-gui( all-elems )

    if draw-results.clicked( next-btn-elem.id ) then new-gui-state
    else show-buy-results-r( new-gui-state )

  show-buy-results-r( init-gui-state )

fun show-victory( init-gui-state : guiState, game-state : gameState ) : <raylib-io, guiExit> guiState
  val victory-text-elem = center-on-point( windowCenter, [
    [GuiElement( "victory-lbl", GuiPosition(0,0), Text(75, "Victory!", darkgray))]
  ])

  val phase-day-elements = [day-element( game-state.day ), phase-element( game-state.phase )]
  val player-elements = get-players-elements( game-state )

  val all-elems = victory-text-elem ++ phase-day-elements ++ player-elements

  fun show-victory-r( prev-gui-state : guiState )
    val (new-gui-state, _) = prev-gui-state.draw-gui( all-elems )
    show-victory-r( new-gui-state )

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