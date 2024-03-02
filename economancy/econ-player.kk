import std/num/float64
import std/os/readline

import cpu-player
import json/json
import game

fun read-json-object()
    // readline only reads a maximum of 1023 characters at a time. When that is
    // exceeded, it takes multiple reads to collect the entire input.
    // Annoyingly, it also trims the ending newline character, so we can't check
    // if the input was truncated.
    //
    // We also can't just check if the last character is a closing brace. It
    // could (in an admittedly unlikely event) be the closing brace for a nested
    // object.
    //
    // Instead, maintain a brace counter. Increment the counter when an opening
    // brace is encountered, and decrement it when a closing brace is found.
    // When the counter reaches zero, we have a complete object and can parse
    // it.
    //
    // NOTE: Thinking about it more, this is probably a better way to injest JSON,
    // because it allows objects with arbitrary newlines.

    fun read-json-object-string( curr-input : string )
      // trace("Waiting...")
      // trace(curr-input)
      val new-input = readline()
      val complete-input = curr-input ++ new-input

      val brace-counter = complete-input.list.foldl( 0, fn( counter, curr-char ){
        if curr-char == '{' then counter + 1
        else if curr-char == '}' then counter - 1
        else counter
       })
      
      if brace-counter == 0 then complete-input
      else read-json-object-string( complete-input )

    val json-string = read-json-object-string( "" )
    json-string.parse-json-string

pub fun string/phase( p : string )
  match p
    "income" -> Income
    "investing" -> Invest
    "buy" -> Buy
    "end" -> Victory

fun to-game-state( obj : jsonValue ) : pure (gameState, int)
  val day-num = obj.key( "day" ).int
  val curr-day = day-num.int/day

  val phase-obj = obj.key( "phase" )

  val curr-phase = match phase-obj.key( "name" ).string
    "victory" -> Victory
    "attacking" -> 
      val attacker-str = phase-obj.key( "attacker" ).int.show
      val attacker-card =
        match phase-obj.key( "attacker_card" )
          Boolean( False ) -> Nothing
          Number( n ) -> Just( n.int )

      Attack( attacker-str, attacker-card )
    s -> s.phase

  if curr-phase.is-victory then (GameState( curr-phase, One, [], []), -1)
  else {
    val player-idx = obj.key( "player" ).int

    val player-objs = obj.key( "players" ).array

    fun obj-to-card( is-attacker : bool, v : jsonValue )
      val card-ty = v.key( "name" ).string.cardType

      val uses = v.key( "uses" ).int
      val attacks = if is-attacker then uses else 0
      val defends = if !is-attacker then uses else 0

      PlayerCard( card-ty, attacks, defends )

    fun obj-to-player( name : string, v : jsonValue )
      val is-attacker = match curr-phase
        Attack( attacker-name, _ ) -> attacker-name == name
        _ -> False

      val buys = v.key( "buys" ).int
      val cards = v.key( "cards" ).array.map( fn(c){ obj-to-card( is-attacker, c ) })
      val coins = v.key( "coins" ).int
      Player( name, Playing, coins, buys, cards )

    val player-names = list(0, player-objs.length - 1).map( show )
    val players = player-names.zip( player-objs ).map( fn( (n,o) ){ obj-to-player( n, o ) } )

    val stock-pairs = match obj.key( "shop" )
      Object( pairs ) -> pairs

    val stock = stock-pairs.map( fn(p){
      Stock( p.name.cardType, p.value.int )
    })

    (GameState( curr-phase, curr-day, stock, players), player-idx)
  }

inline extern flush-output() : io ()
  c inline "fflush( stdout );"

pub fun run-player( s : strategy )
  with handler
    ctl fail( msg : string ) { println( "Failed to parse JSON. Error: " ++ msg ) }

  fun loop()

    val obj = read-json-object()
    val (game-state, player) = obj.to-game-state()
    if game-state.phase.is-victory then ()
    else
      val move = get-cpu-move( game-state, player, s )
      val move-json = match move
        game/types/Pass ->
          match game-state.phase
            Buy -> Array( [String("Pass")] )
            _ -> Array( [Number(0.0)] )

        InvestMove( amt ) -> Array( [Number(amt.float64)] )
        AttackMove( idx ) -> Array( [Number(idx.float64)] )
        BuyMove( ty ) -> Array( [String(ty.show)])

      println( move-json.show )
      flush-output()

      loop()

  loop()
  ()