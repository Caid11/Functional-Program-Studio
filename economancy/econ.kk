import game
import gui

fun game-loop( gui-state : guiState, game-state : gameState )
  match game-state.phase
    Income ->
      val (new-game-state, player-incomes) = game-state.resolve-income()
      gui-state.show-income-results( game-state, player-incomes )
      game-loop( gui-state, new-game-state )
    Invest ->
      val alice-invest = gui-state.get-investment( game-state, "Alice" )
      val investments = [alice-invest, 0, 0, 0]

      val (new-game-state, invest-results) = game-state.resolve-invest( investments )
      gui-state.show-invest-results( game-state, invest-results )

      game-loop( gui-state, new-game-state )
    Attack -> ()
    Buy -> ()


fun main()
  val gui-state = init-gui()

  // TODO: Call WindowClose
  with handler
    ctl exit() { println("All done!") }

  val player-info = gui-state.get-player-info()
  val game-state = get-init-state( player-info )

  game-loop( gui-state, game-state )
