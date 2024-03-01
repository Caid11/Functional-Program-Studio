module behavior-trees

import game

pub type result
  Success
  Fail

type node
  Sequence( children : list<node>)
  Selector( children : list<node> )
  Leaf( f : ( state : gameState, player-idx : int ) -> pure (result, playerMove) )

pub fun traverse( n : node, state : gameState, player-idx : int ) : _e (result, playerMove)
  match n
    Sequence( children ) -> children.foldl( (Success, game/types/Pass), fn( (s,m), c){
      if s.is-fail then (s,m)
      else c.traverse( state, player-idx ) })
    Selector( children ) -> 
      val res = children.find-maybe( fn(c){
        val (s,m) = c.traverse( state, player-idx )
        if s.is-success then Just( (s,m) ) else Nothing
      })
      match res
        Just( r ) -> r
        Nothing -> (Fail, game/types/Pass)
    Leaf( f ) -> f( state, player-idx )


val is-invest = Leaf( fn(state : gameState, _){
  (if state.phase.is-invest then Success else Fail, game/types/Pass) })
val is-attack = Leaf( fn(state : gameState, _){
  (if state.phase.is-attack then Success else Fail, game/types/Pass) })
val is-buy = Leaf( fn(state : gameState, _){
  (if state.phase.is-buy then Success else Fail, game/types/Pass) })

val pass = Leaf( fn(_, _ ){ (Success, game/types/Pass) })

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

    if untapped-idx == -1 then (Success, game/types/Pass)
    else (Success, AttackMove( untapped-idx ))
  })

fun buy( ty : cardType )
  Leaf( fn( state : gameState, player-idx : int ) {
    val player = match state.players[player-idx]
      Just( p ) -> p

    if state.store.get-stock-count( ty ) <= 0 then (Fail, game/types/Pass)
    else if ty.get-price > player.coins then (Fail, game/types/Pass)
    else (Success, BuyMove( ty ))
  })

// Defensive player
//
// This player attempts to buy defensive cards and victory points.
//================================================================================

val defensive-invest = Sequence([
  is-invest,
  pass
])

val defensive-attack = Sequence([
  is-attack,
  choose-first-untapped 
])

val defensive-buy = Sequence([
  is-buy,
  Selector([
    buy( WallOfWealth ),
    buy( Worker ),
    buy( Bubble ),
    buy( ShieldOfGreed ),
    buy( BoardOfMonopoly ),
    pass
  ])
])

pub val defensive = Selector([
  defensive-invest,
  defensive-attack,
  defensive-buy
])