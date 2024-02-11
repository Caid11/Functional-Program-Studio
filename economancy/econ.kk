import game
import gui

fun game-loop( gui-state : guiState, game-state : gameState )
  match game-state.phase
    Income ->
      val (new-game-state, player-incomes) = game-state.resolve-income()
      val new-gui-state = gui-state.show-income-results( game-state, player-incomes )
      game-loop( new-gui-state, new-game-state )
    Invest ->
      val (invest-gui-state, alice-invest) = gui-state.get-investment( game-state, "Alice" )
      val investments = [alice-invest, 0, 0, 0]

      val (new-game-state, invest-results) = game-state.resolve-invest( investments )
      val new-gui-state = invest-gui-state.show-invest-results( game-state, invest-results )

      game-loop( new-gui-state, new-game-state )
    Attack ->
      val (attack-gui-state, alice-card) = gui-state.get-attack-card( game-state, "Alice" )
      val cards = [alice-card, Nothing, Nothing, Nothing]

      val (new-game-state, attack-results) = game-state.resolve-attack( cards )
      val new-gui-state = attack-gui-state.show-attack-results( game-state, attack-results )

      game-loop( new-gui-state, new-game-state )
    Buy ->
      val (buy-gui-state, alice-card) = gui-state.get-buy-card( game-state, "Alice" )
      val cards = [alice-card, Just( Worker ), Just( Worker ), Nothing]

      val (new-game-state, buy-results) = game-state.resolve-buy( cards )
      val new-gui-state = buy-gui-state.show-buy-results( game-state, buy-results )

      game-loop( new-gui-state, new-game-state )


fun main()
  val gui-state = init-gui()

  // TODO: Call WindowClose
  with handler
    ctl exit() { println("All done!") }

  val player-info = gui-state.get-player-info()
  val game-state = get-init-state( player-info )

  game-loop( gui-state, game-state )
