pub type phase
  Income
  Invest

pub fun phase/str( p : phase )
  match p
    Income -> "INCOME"
    Invest -> "INVEST"

pub type day
  One
  Two
  Three

pub fun day/str( d : day )
  match d
    One -> "ONE"
    Two -> "TWO"
    Three -> "THREE"

pub type cardType
  SorcerersStipend
  Worker

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

pub struct playerInitInfo
  name : string

pub fun get-init-state( player-inits : list<playerInitInfo> )
  fun init-player( p : playerInitInfo )
    Player(p.name, 0, [SorcerersStipend])

  val players = player-inits.map( init-player )

  val worker-stock = Stock( Worker, 2 )
  val store = [worker-stock]

  GameState( Income, One, store, players )

fun get-card-income( card : cardType, d : day )
  match card 
    SorcerersStipend ->
      match d
        One -> 2
        _ -> 1

fun get-player-income( state : gameState, p : player )
  val incomes = p.cards.map( fn(c){ get-card-income( c, state.day )})
  val total-income = incomes.foldl( 0, fn(x,y){ x + y} )
  total-income

pub fun resolve-income( state : gameState ) : <pure> (gameState, list<int>)
  val incomes = state.players.map( fn( p ){ get-player-income( state, p )} )

  val new-player-states = zip( state.players, incomes ).map( fn( (p,i) ){ Player( p.player/name, p.coins + i, p.cards ) })
  val new-state = GameState( Invest, state.day, state.store, new-player-states )

  (new-state, incomes)
