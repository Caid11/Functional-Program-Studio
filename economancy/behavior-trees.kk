module behavior-trees

import game

pub type result
  Success
  Fail

type node
  Sequence( children : list<node>)
  Selector( children : list<node> )
  Leaf( f : ( state : gameState, player-idx : int ) -> <pure,moveFound> result )
  Invert( child : node )

effect moveFound
  ctl found( res : playerMove ) : a

pub fun get-move-defensive( state : gameState, player-idx : int ) : _e playerMove
  with ctl found( res : playerMove  ) res
  defensive.traverse( state, player-idx )
  game/types/Pass

fun traverse( n : node, state : gameState, player-idx : int ) : _e result
  match n
    Sequence( children ) -> children.foldl( Success, fn( res, curr ){
      if res.is-fail then res
      else curr.traverse( state, player-idx ) })

    Selector( children ) -> 
      val res = children.find-maybe( fn(c){
        val res = c.traverse( state, player-idx )
        if res.is-success then Just( res )
        else Nothing
      })
      match res
        Just( r ) -> r
        Nothing -> Fail

    Leaf( f ) -> f( state, player-idx )

    Invert( child ) -> match child.traverse( state, player-idx )
      Success -> Fail
      Fail -> Success

fun end( success : bool )
  if success then Success
  else Fail

fun end-node( success : bool )
  Leaf( fn(_,_) { end( success ) })

val is-invest = Leaf( fn(state : gameState, _){ end( state.phase.is-invest ) })
val is-attack = Leaf( fn(state : gameState, _){ end( state.phase.is-attack ) })
val is-buy = Leaf( fn(state : gameState, _){ end( state.phase.is-buy ) })

// TODO: Examine attacker card and prioritize accordingly
val choose-first-untapped =
  Leaf( fn(state : gameState, player-idx : int ){
    val player = match state.players[player-idx]
      Just( p ) -> p

    val is-attacker = match state.phase
      Attack( attacker-name, _ ) -> attacker-name == player.name
      _ -> False

    val untapped-idx = player.cards.index-of( fn(c){
      if is-attacker then c.attacks > 0 else c.defends > 0
    })

    if untapped-idx == -1 then found( game/types/Pass )
    else found( AttackMove( untapped-idx ))
  })

fun buy( ty : cardType )
  Leaf( fn( state : gameState, player-idx : int ) {
    val player = match state.players[player-idx]
      Just( p ) -> p

    if state.store.get-stock-count( ty ) <= 0 then Fail
    else if ty.get-price > player.coins then Fail
    else found( BuyMove( ty ))
  })

fun has-card( has-ty : cardType )
  Leaf( fn( state : gameState, player-idx : int ) {
    val player = match state.players[player-idx]
      Just( p ) -> p

    if player.cards.index-of( fn(c) {c.ty == has-ty } ) != -1 then
      Success
    else Fail
  })

fun move-node( move : playerMove )
  Leaf( fn(_,_){ found( move )})

fun trace-node( msg : string, res : result )
  Leaf( fn(_,_){ 
    // trace( msg )
    res
  })

// Defensive player
//
// This player attempts to buy defensive cards and victory points.
//================================================================================

// If possible, choose the card with the lowest defense that survives the encounter
val choose-survives-lowest-defense = Leaf( fn( state : gameState, player-idx : int ) {
  val player = state.players[player-idx].unjust

  val (is-attacker, attacking-card) = match state.phase
    Attack( attacker-name, attacking ) ->
      match attacking
        Just( idx ) -> (attacker-name == player.name, state.get-player( attacker-name ).cards[idx].unjust)
        Nothing -> found( game/types/Pass )

  fun is-tapped(card)
    if is-attacker then card.attacks <= 0 else card.defends <= 0

  val (attack-value, _) = attacking-card.ty.get-card-stats()

  val best-card = player.cards.map-indexed( fn( i, c ){ (i,c) } ).foldl( -1, fn( curr-idx, (next-idx,next-card) ){
    val (_, next-defense) = next-card.ty.get-card-stats

    if is-tapped( next-card ) then curr-idx
    else if next-defense < attack-value then curr-idx
    else if curr-idx == -1 then next-idx
    else
      val (_, curr-defense) = player.cards.list/@index(curr-idx).unjust.ty.get-card-stats
      if next-defense < curr-defense then next-idx
      else curr-idx
  })

  if best-card > 0 then found( AttackMove( best-card ) )
  else Fail
})

// If possible, choose the card with the lowest attack value that causes the attacking card to faint
val choose-lowest-attack-wins = Leaf( fn( state : gameState, player-idx : int ) {
  val player = state.players[player-idx].unjust

  val (is-attacker, attacking-card) = match state.phase
    Attack( attacker-name, attacking ) ->
      match attacking
        Just( idx ) -> (attacker-name == player.name, state.get-player( attacker-name ).cards[idx].unjust)
        Nothing -> found( game/types/Pass )

  fun is-tapped(card)
    if is-attacker then card.attacks <= 0 else card.defends <= 0

  val (_, attacker-defense) = attacking-card.ty.get-card-stats()

  val best-card = player.cards.map-indexed( fn( i, c ){ (i,c) } ).foldl( -1, fn( curr-idx, (next-idx,next-card) ){
    val (next-attack, _) = next-card.ty.get-card-stats
    if is-tapped( next-card ) then curr-idx
    else if attacker-defense >= next-attack then curr-idx
    else if curr-idx == -1 then next-idx
    else
      val (curr-attack, _) = match player.cards.list/@index(curr-idx)
        Just( c ) -> c.ty.get-card-stats
      if next-attack < curr-attack then next-idx
      else curr-idx
  })

  if best-card > 0 then found( AttackMove( best-card ) )
  else Fail
})

// Choose the least valuable card in the players hand.
// We'll define value as attack + defense + victory points
val choose-least-valuable = Leaf( fn( state : gameState, player-idx : int ) {
  val player = state.players[player-idx].unjust

  val is-attacker = match state.phase
    Attack( attacker-name, _ ) -> attacker-name == player.name

  fun is-tapped(card)
    if is-attacker then card.attacks <= 0 else card.defends <= 0

  fun get-card-value( idx )
    val card = match player.cards[idx]
      Just( c ) -> c
    
    val (attack, defense) = card.ty.get-card-stats()
    val victory-points = card.ty.get-card-victory-points()
    attack + defense + victory-points

  val best-card = player.cards.map-indexed( fn( i, c ){ (i,c) } ).foldl( 0, fn( curr-idx : int, (next-idx,next-card) ){
    val curr-value = get-card-value(curr-idx)
    val next-value = get-card-value(next-idx)

    if is-tapped( next-card ) then curr-idx
    else if curr-idx == 0 then next-idx
    else if next-value > curr-value then curr-idx
    else next-idx
  })

  found( AttackMove( best-card ) )
})

// TODO: Invest if we have too few attacks or enough money that we can buy out all other players
val defensive-invest = Sequence([
  is-invest,
  move-node( game/types/Pass )
])

// TODO: Handle case where we're attacking
val defensive-attack = Sequence([
  is-attack,
  Selector([
    choose-survives-lowest-defense,
    choose-lowest-attack-wins,
    choose-least-valuable
  ])
])

val has-enough-defends = Leaf( fn( state : gameState, player-idx : int ) {
  val player = state.players[player-idx].unjust
  val max-attacks = state.players.map-indexed( fn(i, p){
    if i == player-idx then 0 else p.num-attacks }).maximum
  end( player.num-defends >= max-attacks )
})

val has-enough-earning = Leaf( fn( state : gameState, player-idx : int ) {
  val player = state.players[player-idx].unjust

  val earning-over-days = [One, Two, Three].map( fn(d){
    get-player-income( d, player, 0, player.cards )
  }).sum

  end( earning-over-days > 7 )
})

// The player has enough defense if they have a card that can defend against the
// most powerful card in possesion of another player
val has-high-enough-defense = Leaf( fn( state : gameState, player-idx : int ) {
  val player = state.players[player-idx].unjust

  val highest-attack = state.players.flatmap( fn(p){ p.cards }).map( fn(c){ 
    val (attack, _) = c.ty.get-card-stats
    attack
  }).maximum

  val player-max-defend = player.cards.map( fn(c){
    val (_, defense) = c.ty.get-card-stats
    defense
   }).maximum

  end( player-max-defend >= highest-attack )
})

val is-day-one = Leaf( fn( state : gameState, _ ) {
  end( state.day.is-one )
})

val is-day-two = Leaf( fn( state : gameState, _ ) {
  end( state.day.is-two )
})

val defensive-buy = Sequence([
  is-buy,

  // Ensure the player isn't behind in number of defends
  Selector([
    // TODO: Consider whether or not the player has multiple buys
    has-enough-defends,

    trace-node( "defends", Fail ),

    buy( WallOfWealth ),
    buy( Golem ),
    buy( Thug ),
    buy( Bubble ),
    buy( SeniorWorker ),
    buy( Worker ),
  ]),

  // Opportunistically buy a Shield of Greed
  Selector([
    has-card( ShieldOfGreed ),
    trace-node( "Shield of Greed", Fail ),
    buy( ShieldOfGreed ),
    end-node( True )
  ]),

  // If another player has a card with higher attack than this player's best
  // card's defense, try to buy a card to defend against it.
  Selector([
    has-high-enough-defense,

    trace-node( "Defense", Fail ),

    buy( Bubble ),
    buy( Golem ),
    buy( ShieldOfGreed ),

    // If we haven't been able to buy defensive cards, continue on to buy
    // economy cards so we don't fall behind in attacks
    end-node( True )
  ]),

  // Ensure the player is earning enough
  Selector([
    has-enough-earning,

    trace-node( "Earning", Fail ),

    Selector([
      Sequence([
        is-day-two,
        buy( GoldFish )
      ]),

      Sequence([
        is-day-one,
        buy( Thug )
      ]),

      buy( ShieldOfGreed ),
      buy( SeniorWorker ),
      buy( Worker ),

      // Continue trying to buy cards if we haven't been able to.
      end-node( True )
    ])
  ]),

  trace-node( "Fallthrough", Success ),

  Selector([
    // Finally, start purchasing victory points
    buy( Incantation ),
    buy( BoardOfMonopoly ),

    end-node( True )
  ]),

  // Fallthrough: Attempt to buy something so we don't fall behind
  buy( Worker )
])

val defensive = Selector([
  defensive-invest,
  defensive-attack,
  defensive-buy
])

// Misc utility functions
//================================================================================

fun num-attacks( p : player )
  p.cards.map( fn(c){
    val info = c.ty.get-card-attacks-defends
    info.attacks
  }).sum

fun num-defends( p : player )
  p.cards.map( fn(c){
    val info = c.ty.get-card-attacks-defends
    info.defends
  }).sum