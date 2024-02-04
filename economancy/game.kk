pub type phase
  Income

pub type day
  One
  Two
  Three

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

// TODO: Players are hard-coded
pub fun get-init-state()
  val alice = Player( "Alice", 0, [] )
  val bob = Player( "Bob", 0, [] )
  val charlie = Player( "Charle", 0, [] )
  val diane = Player( "Diane", 0, [] )
  val players = [alice, bob, charlie, diane]

  val worker-stock = Stock( Worker, 2 )
  val store = [worker-stock]

  GameState( Income, One, store, players )