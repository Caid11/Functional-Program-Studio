import gui

fun main()
  var game-state := init-game()

  fun game-loop()
    val gui-cmd = game-state.update()

    match gui-cmd
      Nothing -> game-loop()
      Just( Start ) -> 
        println("Game started!")
        game-loop()
      Just( Quit ) -> ()

  game-loop()
