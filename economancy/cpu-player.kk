import std/num/random
import std/num/float64

import game

// TODO: Take randomness out of these functions

type strategy
  Pass
  Random

fun get-invest( game-state : gameState, player-idx : int, s : strategy ) : <pure,random> playerMove
  match s
    cpu-player/Pass -> InvestMove( 0 )
    Random ->
      val player = game-state.players[player-idx].unjust
      val rand = random-float64()
      InvestMove( int( rand * player.coins.float64 ) )

// TODO: Switch this from using maybe<int> to in (Sorcerer's Stipend represents no attack)
fun get-attack( game-state : gameState, player-idx : int, s : strategy ) : <pure,random> playerMove
  match s
    cpu-player/Pass -> game/types/Pass
    Random ->
      val player = game-state.players[player-idx].unjust
      val is-attacker = match game-state.phase
        Attack( attacker-name, _ ) -> attacker-name == player.name
        _ -> False

      val cards-with-idxs = list(0, player.cards.length - 1).zip( player.cards )
      val playable-cards = cards-with-idxs.filter( fn( (_,c) ){ if is-attacker then c.attacks > 0 else c.defends > 0} )

      if playable-cards.length == 0 then Pass
      else
        // NOTE: This doesn't include passing as a possible choice
        val rand = random-float64()
        val playable-idx = int((playable-cards.length - 1).float64 * rand)
        val (i,_) = playable-cards[playable-idx].unjust
        AttackMove( i )


fun get-buy( game-state : gameState, player-idx : int, s : strategy ) : <pure,random> playerMove
  match s
    cpu-player/Pass -> game/types/Pass
    Random ->
      val player = game-state.players[player-idx].unjust

      val available-stock : list<game/types/stock> = game-state.store.filter( fn(st){ st.remaining > 0})
      val affordable-stock = available-stock.filter( fn(st){ st.stock/card.get-price <= player.coins})

      if affordable-stock.length == 0 then game/types/Pass
      else
        val rand = random-float64()
        val choice-idx = int((affordable-stock.length - 1).float64 * rand)
        val choice = affordable-stock[choice-idx].unjust
        BuyMove( choice.card )

pub fun get-cpu-move( game-state : gameState, idx : int, s : strategy ) : <pure,random> playerMove
  if game-state.players[idx].unjust.status.is-defeated then Pass
  else
    match game-state.phase
      Invest -> get-invest( game-state, idx, s)
      Buy -> get-buy( game-state, idx, s)
      Attack -> get-attack( game-state, idx, s)
