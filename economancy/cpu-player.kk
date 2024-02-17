import std/num/random
import std/num/float64

import game

// TODO: Take randomness out of these functions

type strategy
  Pass
  Random

pub fun get-invest( game-state : gameState, player-name : string, s : strategy ) : <pure,random> int
  match s
    Pass -> 0
    Random ->
      val player = game-state.get-player( player-name )
      val rand = random-float64()
      int( rand * player.coins.float64 )

// TODO: Switch this from using maybe<int> to in (Sorcerer's Stipend represents no attack)
pub fun get-attack( game-state : gameState, player-name : string, s : strategy ) : <pure,random> maybe<int>
  match s
    Pass -> Nothing
    Random ->
      val player = game-state.get-player( player-name )
      val is-attacker = match game-state.attacker
        Nothing -> False
        Just( name ) ->
          name == player-name

      val cards-with-idxs = list(0, player.cards.length - 1).zip( player.cards )
      val playable-cards = cards-with-idxs.filter( fn( (_,c) ){ if is-attacker then c.attacks > 0 else c.defends > 0} )

      if playable-cards.length == 0 then Nothing
      else
        // NOTE: This doesn't include passing as a possible choice
        val rand = random-float64()
        val playable-idx = int((playable-cards.length - 1).float64 * rand)
        val (i,_) = playable-cards[playable-idx].unjust
        Just( i )


pub fun get-buy( game-state : gameState, player-name : string, s : strategy ) : <pure,random> maybe<cardType>
  match s
    Pass -> Nothing
    Random ->
      val player = game-state.get-player( player-name )

      val available-stock = game-state.store.filter( fn(st){ st.remaining > 0})
      val affordable-stock = available-stock.filter( fn(st){ st.card.get-price <= player.coins})

      if affordable-stock.length == 0 then Nothing
      else
        val rand = random-float64()
        val choice-idx = int((affordable-stock.length - 1).float64 * rand)
        val choice = affordable-stock[choice-idx].unjust
        Just( choice.card )
