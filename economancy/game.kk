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

pub struct stock
  card : cardType
  remaining : int

pub struct player
  name : string
  coins : int
  cards : list<cardType>

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

pub fun get-init-state( player-inits : list<playerInitInfo> )
  fun init-player( p : playerInitInfo )
    Player(p.name, 0, [SorcerersStipend, Worker])

  val players = player-inits.map( init-player )

  // TODO: Set stock based on number of players
  val store = [
    Stock( Apprentice, 3 ),
    Stock( BoardOfMonopoly, 3 ),
    Stock( Bubble, 3 ),
    Stock( Ghost, 3 ),
    Stock( GoldFish, 3 ),
    Stock( Golem, 3 ),
    Stock( Incantation, 3 ),
    Stock( MagicBeanStock, 3 ),
    Stock( SeniorWorker, 3 ),
    Stock( ShieldOfGreed, 3 ),
    Stock( Thug, 3 ),
    Stock( WallOfWealth, 3 ),
    Stock( Worker, 3 ),
  ]

  GameState( Income, One, store, players, Nothing )

fun get-card-income( card : cardType, d : day )
  match card 
    SorcerersStipend ->
      match d
        One -> 2
        _ -> 1
    Worker ->
      match d
        Two -> 1
        Three -> 1
        _ -> 0

fun get-player-income( state : gameState, p : player )
  val incomes = p.cards.map( fn(c){ get-card-income( c, state.day )})
  val total-income = incomes.foldl( 0, fn(x,y){ x + y} )
  total-income

pub fun resolve-income( state : gameState ) : <pure> (gameState, list<int>)
  val incomes = state.players.map( fn( p ){ get-player-income( state, p )} )
  val new-players = zip( state.players, incomes ).map( fn( (p,i) ){ Player( p.player/name, p.coins + i, p.cards ) })
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
  DrawNoFaint
  DrawBothFaint
  AttackerFainted
  DefenderFainted
  DefenderDefeated

pub struct attackResult
  attacker-name : string
  attacker-card : cardType
  defender-cards : list<cardType>
  outcomes : list<attackOutcome>
  
pub fun resolve-attack( state : gameState, attack-cards : list<maybe<int>> ) : pure (gameState, attackResult)
  // TODO: Actually resolve attack phase
  val dummy-outcomes = [DrawBothFaint, AttackerFainted, DefenderDefeated]
  val chosen = [Worker, Worker, Worker]
  val dummy-result = AttackResult( state.attacker.unjust, Worker, chosen, dummy-outcomes )
  (state( phase = Buy, attacker = Nothing ), dummy-result)

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