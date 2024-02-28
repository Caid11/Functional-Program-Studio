import std/num/random

import raylib/raylib

import cpu-player
import game
import gui
import player-info

fun main()
  with ctl exit() { println("All done!") }

  var gui-state := init-gui()
  val player-info = gui-state.get-player-info()

  // TODO: Call WindowClose
  with ctl get-move( game-state : gameState, player-idx : int )
    match player-info[player-idx]
      Just( PlayerInitInfo( _, ty ) ) ->
        match ty
          Human ->
            val (new-gui-state, move) = gui-state.gui/get-move( game-state, player-idx )
            gui-state := new-gui-state
            resume(move)
          Cpu( strat ) ->
            resume(get-cpu-move( game-state, player-idx, strat ))

  fun game-loop( game-state : gameState )
    val (new-game-state, phase-result) = game-state.resolve-current-phase()
    gui-state := gui-state.show-phase-results( game-state, phase-result )
    game-loop( new-game-state )

  val player-names = player-info.map( name )
  val game-state = get-init-state( player-names )

  game-loop( game-state )
