pub type phase
  Income
  Invest
  Attack
  Buy

pub fun phase/str( p : phase )
  match p
    Income -> "INCOME"
    Invest -> "INVEST"
    Attack -> "ATTACK"
    Buy -> "BUY"

pub type day
  One
  Two
  Three

pub fun day/str( d : day )
  match d
    One -> "1"
    Two -> "2"
    Three -> "3"

pub type cardType
  SorcerersStipend
  Apprentice
  BoardOfMonopoly
  Bubble
  Ghost
  GoldFish
  Golem
  Incantation
  MagicBeanStock
  SeniorWorker
  ShieldOfGreed
  Thug
  WallOfWealth
  Worker

// TODO: It feels like there should be something built in for this...
pub fun cardType/cmp( x : cardType, y : cardType )
  match x
    SorcerersStipend -> match y
      SorcerersStipend -> True
      _ -> False
    Apprentice -> match y
      Apprentice -> True
      _ -> False
    BoardOfMonopoly -> match y
      BoardOfMonopoly -> True
      _ -> False
    Bubble -> match y
      Bubble -> True
      _ -> False
    Ghost -> match y
      Ghost -> True
      _ -> False
    GoldFish -> match y
      GoldFish -> True
      _ -> False
    Golem -> match y
      Golem -> True
      _ -> False
    Incantation -> match y
      Incantation -> True
      _ -> False
    MagicBeanStock -> match y
      MagicBeanStock -> True
      _ -> False
    SeniorWorker -> match y
      SeniorWorker -> True
      _ -> False
    ShieldOfGreed -> match y
      ShieldOfGreed -> True
      _ -> False
    Thug -> match y
      Thug -> True
      _ -> False
    WallOfWealth -> match y
      WallOfWealth -> True
      _ -> False
    Worker -> match y
      Worker -> True
      _ -> False

fun get-card-stats( ty : cardType ) : pure (int, int)
  (1,1) // TODO: Implement

pub struct stock
  card : cardType
  remaining : int

pub struct playerCard
  ty : cardType
  attacks : int
  defends : int
  
pub struct player
  name : string
  coins : int
  buys : int
  cards : list<playerCard>

pub struct gameState
  phase : phase
  day : day
  store : list<stock>
  players : list<player>
  attacker : maybe<string>

type playerType
  Human
  Cpu

pub struct playerInitInfo
  name : string
  ty : playerType

fun get-init-stock( num-players : int ) : pure list<stock>
  [
    Stock( Apprentice, num-players ),
    Stock( BoardOfMonopoly, 2 * num-players ),
    Stock( Bubble, num-players ),
    Stock( Ghost, 2 * num-players ),
    Stock( GoldFish, num-players ),
    Stock( Golem, num-players ),
    Stock( Incantation, 3 * num-players ),
    Stock( MagicBeanStock, num-players ),
    Stock( SeniorWorker, 2 * num-players ),
    Stock( ShieldOfGreed, num-players ),
    Stock( Thug, num-players ),
    Stock( WallOfWealth, 2 * num-players ),
    Stock( Worker, 2 * num-players ),
  ]

pub fun get-init-state( player-inits : list<playerInitInfo> )
  fun init-player( p : playerInitInfo )
    Player(p.name, 0, 0, [PlayerCard(SorcerersStipend, 0, 0), PlayerCard(Worker, 0, 0)])

  val players = player-inits.map( init-player )
  val stock = get-init-stock( player-inits.length )
  GameState( Income, One, stock, players, Nothing )

fun get-card-income( player-coins : int, card : cardType, d : day )
  match card 
    SorcerersStipend ->
      match d
        One -> 2
        _ -> 1
    Apprentice ->
      match d
        One -> 1
        Two -> 1
        _ -> 0
    BoardOfMonopoly -> 0
    Bubble -> 0
    Ghost ->
      match d
        One -> 1
        _ -> 0
    GoldFish ->
      match d
        Three -> 4
        _ -> 0
    Golem -> 0
    Incantation -> 0
    MagicBeanStock -> player-coins / 3
    SeniorWorker -> 1
    ShieldOfGreed -> 0
    Thug ->
      match d
        Two -> 1
        _ -> 0
    WallOfWealth ->
      match d
        One -> 1
        _ -> 0
    Worker ->
      match d
        Two -> 1
        Three -> 1
        _ -> 0

fun get-player-income( d : day, p : player, coins : int, cards : list<playerCard> ) : pure int
  match cards
    Nil -> coins
    Cons( c, cs ) -> get-player-income( d, p, coins + get-card-income( coins, c.ty, d ), cs)

fun get-card-buys( c : cardType, d : day ) : pure int
  match c
    Apprentice ->
      match d
        Three -> 1
        _ -> 0
    _ -> 0

fun get-player-buys( d : day, p : player ) : pure int
  val card-buys = p.cards.map( fn( c ){ get-card-buys( c.ty, d )}).sum
  card-buys + 1

fun get-card-attacks-defends( c : cardType ) : pure playerCard
  match c
    SorcerersStipend -> PlayerCard( c, 0, 0 )
    Bubble -> PlayerCard( c, 0, 1 )
    WallOfWealth -> PlayerCard( c, 1, 2 )
    _ -> PlayerCard( c, 1, 1 )

pub fun resolve-income( state : gameState ) : <pure> (gameState, list<int>)
  val incomes = state.players.map( fn( p ){ get-player-income( state.day, p, p.coins, p.cards )} )
  val buys = state.players.map( fn( p ){ get-player-buys( state.day, p )})
  val cards = state.players.map( fn( p ){ p.cards.map( fn( c ){ get-card-attacks-defends( c.ty ) })})
  val new-players = state.players.zip( incomes ).zip( buys ).zip( cards ).map( fn( (((p,i),b),c) ){ p( coins = p.coins + i, buys = b, cards = c ) })
  val new-state = state( phase = Invest, players = new-players )
  (new-state, incomes)

pub struct investResult
  winner-name : maybe<string>
  investments : list<int>

pub fun resolve-invest( state : gameState, player-invests : list<int> ) : <pure> (gameState, investResult)
  val players-and-invests = state.players.zip( player-invests )
  val new-players = players-and-invests.map( fn( (p,i) ) { p( coins = p.coins - i) })

  val max-invest = player-invests.maximum
  val max-count = player-invests.foldl( 0, fn(c, i){ if i == max-invest then c + 1 else c })

  // If all investments are the same, there is no winner
  if max-count > 1 then
    (state( phase = Buy, players = new-players ), InvestResult( Nothing, player-invests ))
  // Otherwise, the player with the maximum investment wins
  else
    val (winner,_) = players-and-invests.find( fn( (p, i) ){ i == max-invest } ).unjust
    val winner-name = winner.player/name

    (state( phase = Attack, players = new-players, attacker = Just( winner-name ) ),
      InvestResult( Just( winner-name ), player-invests ) )

pub type attackOutcome
  Okay
  Fainted
  Defeated

pub type attackRole
  Attacker
  Defender

pub struct attackResult
  player-name : string 
  role : attackRole
  card : maybe<cardType>
  outcome : attackOutcome
  
fun drop-idx( xs : list<a>, idx : int ) : pure list<a>
  list(0, xs.length - 1).zip( xs ).filter( fn( (i,x) ){ i != idx } ).map( fn( (_,x) ){ x })

fun resolve-outcome( x : maybe<cardType>, y : maybe<cardType> ) : pure attackOutcome
  match y
    Nothing -> Okay
    Just( y-ty ) ->
      // Player didn't supply a card and is defeated
      match x
        Nothing -> Defeated
        Just( x-ty ) ->
          val (_, x-defense) = x-ty.get-card-stats()
          val (y-attack, _) = y-ty.get-card-stats()
          if y-attack > x-defense then Fainted else Okay

pub fun resolve-attack( state : gameState, attack-cards : list<maybe<int>> ) : pure (gameState, list<attackResult>)
  val attacker-name = state.attacker.unjust
  val attacker-idx = state.players.index-of( fn( p ){ p.name == attacker-name } )

  fun get-choice-ty( idx )
    match attack-cards[idx].unjust
      Nothing -> Nothing
      Just( i ) -> Just( state.players[idx].unjust.cards[i].unjust.ty )

  val attacker-choice = get-choice-ty( attacker-idx )

  fun resolve-outcomes( attacker-idx : int, curr-idx : int, outcomes : list<attackOutcome> )
    if curr-idx >= attack-cards.length then outcomes
    else if curr-idx == attacker-idx then
      val defender-choices = list(0, attack-cards.length - 1).map( get-choice-ty ).drop-idx( attacker-idx )

      val attacker-outcomes = defender-choices.map( fn( c ){ resolve-outcome( attacker-choice, c )})
      val attacker-outcome = if attacker-outcomes.any( is-fainted ) then Fainted else Okay
      resolve-outcomes( attacker-idx, curr-idx + 1, outcomes ++ [attacker-outcome])
    else
      val defender-choice = get-choice-ty( curr-idx )
      val outcome = resolve-outcome( defender-choice, attacker-choice )
      resolve-outcomes( attacker-idx, curr-idx + 1, outcomes ++ [outcome])

  val outcomes = resolve-outcomes( attacker-idx, 0, [] )

  fun get-role( p : player )
    if p.name == attacker-name then Attacker
    else Defender

  // TODO: We can probably just do this once
  val choices = list(0, attack-cards.length - 1).map( get-choice-ty )
  val results = state.players.zip( choices ).zip( outcomes ).map( fn( ((p,c),o) ){ AttackResult(p.name, get-role( p ), c, o)} )
  (state( phase = Buy ), results)

  // Remove defeated players
  // Set phase based on remaining attack cards (or pass)

pub struct buyResult
  cards : list<maybe<cardType>>
  purchase-conflict : list<bool>
  purchase-amts : list<int>

pub fun resolve-buy( state : gameState, buy-cards : list<maybe<cardType>> ) : pure (gameState, buyResult)
  val dummy-cards = [Just(Worker), Just(Apprentice), Nothing, Just(Apprentice)]
  val dummy-conflict = [False, True, False, True]
  val dummy-amts = [2, 3, 0, 3]
  val dummy-result = BuyResult( dummy-cards, dummy-conflict, dummy-amts )
  (state, dummy-result)