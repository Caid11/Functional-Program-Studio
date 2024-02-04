import game
import gui

fun game-loop( prev-gui-state : guiState, game-state : gameState )
  val update-res : guiUpdateResult = prev-gui-state.update( game-state )
  val new-gui-state : guiState = update-res.gui-state

  match update-res.gui-cmd
    Nothing -> game-loop( new-gui-state, game-state )
    Just( Start ) -> 
      println("Game started!")
      game-loop( update-res.gui-state, game-state )
    Just( Quit ) -> ()

fun main()
  val gui-state = init-gui()
  val game-state = get-init-state()

  game-loop( gui-state, game-state )
