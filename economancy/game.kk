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
  Worker

pub fun cardType/cmp( x : cardType, y : cardType )
  match x
    SorcerersStipend -> match y
      SorcerersStipend -> True
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

pub struct playerInitInfo
  name : string

pub fun get-init-state( player-inits : list<playerInitInfo> )
  fun init-player( p : playerInitInfo )
    Player(p.name, 0, [SorcerersStipend, Worker])

  val players = player-inits.map( init-player )

  val worker-stock = Stock( Worker, 2 )
  val store = [worker-stock]

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