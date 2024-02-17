import std/num/random

import cpu-player
import game
import gui
import raylib/raylib

fun get-invests( players : list<playerInitInfo>,
                 game-state : gameState,
                 gui-state : guiState,
                 curr-invests : list<int> ) : <guiExit, raylib-io, random> (guiState, list<int>)
  match players
    Nil -> (gui-state, curr-invests)
    Cons( p, ps ) ->
      match p.ty
        Cpu ->
          val i = get-invest( game-state, p.name, Random )
          get-invests( ps, game-state, gui-state, curr-invests ++ [i] )
        Human ->
          val (new-gui-state, i) = gui-state.get-investment( game-state, p.name )
          get-invests( ps, game-state, new-gui-state, curr-invests ++ [i] )

fun get-attacks( players : list<playerInitInfo>,
                 game-state : gameState,
                 gui-state : guiState,
                 curr-attacks : list<maybe<int>> ) : <guiExit, raylib-io, random> (guiState, list<maybe<int>>)
  match players
    Nil -> (gui-state, curr-attacks)
    Cons( p, ps ) ->
      match p.ty
        Cpu ->
          val i = get-attack( game-state, p.name, Random )
          get-attacks( ps, game-state, gui-state, curr-attacks ++ [i] )
        Human ->
          // Attacker choice is always first card in curr-attacks
          val attacker-card-idx = if curr-attacks.length > 0 then curr-attacks[0].unjust else Nothing
          val (new-gui-state, i) = gui-state.get-attack-card( game-state, p.name, attacker-card-idx )
          get-attacks( ps, game-state, new-gui-state, curr-attacks ++ [i] )

fun get-buys( players : list<playerInitInfo>,
              game-state : gameState,
              gui-state : guiState,
              curr-buys : list<maybe<cardType>> ) : <guiExit, raylib-io, random> (guiState, list<maybe<cardType>>)
  match players
    Nil -> (gui-state, curr-buys)
    Cons( p, ps ) ->
      match p.ty
        Cpu ->
          val i = get-buy( game-state, p.name, Random )
          get-buys( ps, game-state, gui-state, curr-buys ++ [i] )
        Human ->
          val (new-gui-state, i) = gui-state.get-buy-card( game-state, p.name )
          get-buys( ps, game-state, new-gui-state, curr-buys ++ [i] )

// TODO: Maybe register handlers for getting player input?
fun game-loop( player-info : list<playerInitInfo>, gui-state : guiState, game-state : gameState )
  match game-state.phase
    Income ->
      val (new-game-state, player-incomes) = game-state.resolve-income()
      val new-gui-state = gui-state.show-income-results( game-state, player-incomes )
      game-loop( player-info, new-gui-state, new-game-state )
    Invest ->
      val (invest-gui-state, investments) = get-invests( player-info, game-state, gui-state, [])
      val (new-game-state, invest-results) = game-state.resolve-invest( investments )
      val result-gui-state = invest-gui-state.show-invest-results( game-state, invest-results )

      game-loop( player-info, result-gui-state, new-game-state )
    Attack ->
      // TODO: Have attacker choose card first, highlight it when defenders are choosing their cards.
      // Reorder players so that attacker chooses card first.
      val attacker-idx = player-info.index-of( fn(p){ p.name == game-state.attacker.unjust } )
      val attacker-info = player-info[attacker-idx].unjust
      val defender-info = player-info.filter( fn(p){ p.name != game-state.attacker.unjust })
      val player-info-reordered = [attacker-info] ++ defender-info

      val (attack-gui-state, attack-cards) = get-attacks( player-info-reordered, game-state, gui-state, [] )
      
      // Reorder attack cards so attacker is in the right spot.
      val attacker-choice = attack-cards[0].unjust
      val defender-choices = attack-cards.drop(1)
      val attack-cards-reordered = defender-choices.take( attacker-idx ) ++ [attacker-choice] ++ defender-choices.drop(attacker-idx)
      val (new-game-state, attack-results) = game-state.resolve-attack( attack-cards-reordered )
      val result-gui-state = attack-gui-state.show-attack-results( game-state, attack-results )

      game-loop( player-info, result-gui-state, new-game-state )
    Buy ->
      val (buy-gui-state, buy-cards) = get-buys( player-info, game-state, gui-state, [] )
      val (new-game-state, buy-results) = game-state.resolve-buy( buy-cards )
      val result-gui-state = buy-gui-state.show-buy-results( game-state, buy-results )

      game-loop( player-info, result-gui-state, new-game-state )
    Victory ->
      gui-state.show-victory( game-state )

fun main()
  val gui-state = init-gui()

  // TODO: Call WindowClose
  with handler
    ctl exit() { println("All done!") }

  val player-info = gui-state.get-player-info()
  val game-state = get-init-state( player-info )

  game-loop( player-info, gui-state, game-state )
