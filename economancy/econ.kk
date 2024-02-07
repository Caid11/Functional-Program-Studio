import game
import gui

fun game-loop( gui-state : guiState, game-state : gameState )
  match game-state.phase
    Income ->
      val (new-game-state, player-incomes) = game-state.resolve-income()
      gui-state.show-income-results( game-state, player-incomes )
      game-loop( gui-state, new-game-state )
    Invest ->
      gui-state.show-invest( game-state )
      game-loop( gui-state, game-state )


fun main()
  val gui-state = init-gui()

  // TODO: Call WindowClose
  with handler
    ctl exit() { println("All done!") }

  val player-info = gui-state.get-player-info()
  val game-state = get-init-state( player-info )

  game-loop( gui-state, game-state )
