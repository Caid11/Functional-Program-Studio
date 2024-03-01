module game/test-resolve

import game/resolve
import game/state
import game/types

fun expect-eq( name : string, expected : player, result : player )
  if result != expected then
    println("[FAILED] " ++ name )
    println("    Actual:\n" ++ result.show )
    println("    Expected:\n" ++ expected.show )
  else
    println("[SUCCEEDED] " ++ name )

// Invest tests
//================================================================================

val invest-player = Player( "Alice", Playing, 5, 1, [])
val invest-state = GameState(Invest, One, [], [invest-player])

fun playerCannotInvestNegative()
  with ctl get-move( game-state : gameState, player-idx : int ) resume( InvestMove( -1 ) )
  val (new-state, _) = invest-state.resolve-current-phase()
  expect-eq( "playerCannotInvestNegative", invest-player(status = Disqualified), new-state.players[0].unjust )

fun playerCannotInvestMoreThanCoins()
  with ctl get-move( game-state : gameState, player-idx : int ) resume( InvestMove( 100 ) )
  val (new-state, _) = invest-state.resolve-current-phase()
  expect-eq( "playerCannotInvestMoreThanCoins", invest-player(status = Disqualified), new-state.players[0].unjust )

// Attack tests
//================================================================================

val attack-alice = Player( "Alice", Playing, 5, 1, [PlayerCard(Worker, 0, 0)])
val attack-bob = Player( "Bob", Playing, 5, 1, [PlayerCard(Worker, 0, 0)])
val attack-state = GameState(Attack( "Alice", Nothing), One, [], [attack-alice, attack-bob])

fun playerCannotAttackOrDefendWithNonExistentCard()
  with ctl get-move( game-state : gameState, player-idx : int ) resume( AttackMove( 100 ))
  val (new-state, _) = attack-state.resolve-current-phase()
  expect-eq( "playerCannotAttackWithNonExistentCard", attack-alice(status = Disqualified), new-state.players[0].unjust )
  expect-eq( "playerCannotDefendWithNonExistentCard", attack-bob(status = Disqualified), new-state.players[1].unjust )

fun playerCannotAttackOrDefendWithNoUses()
  with ctl get-move( game-state : gameState, player-idx : int ) resume( AttackMove( 0 ))
  val (new-state, _) = attack-state.resolve-current-phase()
  expect-eq( "playerCannotAttackWithNoUses", attack-alice(status = Disqualified), new-state.players[0].unjust )
  expect-eq( "playerCannotDefendWithNoUses", attack-bob(status = Disqualified), new-state.players[1].unjust )

// Buy tests
//================================================================================

val buy-player = Player( "Alice", Playing, 5, 1, [PlayerCard(Worker, 0, 0)])
val buy-player-no-coins = buy-player( coins = 0 )
val buy-player-no-buys = buy-player( buys = 0 )

val buy-state = GameState(Buy, One, [Stock(Worker, 5), Stock(SeniorWorker, 0)], [buy-player, buy-player-no-coins, buy-player-no-buys])

fun playerBuyTests()
  with ctl get-move( game-state : gameState, player-idx : int )
    match player-idx
      0 -> resume( BuyMove( SeniorWorker ))
      1 -> resume( BuyMove( Worker ))
      2 -> resume( BuyMove( Worker ))

  val (new-state, _ ) = buy-state.resolve-current-phase()
  expect-eq( "playerCannotBuyOutOfStock", buy-player(status = Disqualified, buys = 0), new-state.players[0].unjust )
  expect-eq( "playerCannotBuyTooExpensive", buy-player-no-coins(status = Disqualified, buys = 0), new-state.players[1].unjust )
  expect-eq( "playerCannotBuyWithNoBuys", buy-player-no-buys(status = Disqualified), new-state.players[2].unjust )

fun main()
  playerCannotInvestNegative()
  playerCannotInvestMoreThanCoins()
  playerCannotAttackOrDefendWithNonExistentCard()
  playerCannotAttackOrDefendWithNoUses()
  playerBuyTests()