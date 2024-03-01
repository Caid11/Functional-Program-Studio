module game/types

pub type phase
  Income
  Invest
  Attack( attacker-name : string, attacker-choice : maybe<int> )
  Buy
  Victory

pub type day
  One
  Two
  Three

pub type attackOutcome
  CardOkay
  CardFainted
  PlayerDefeated

pub type attackRole
  Attacker
  Defender

pub struct attackResult
  player-name : string 
  role : attackRole
  card : maybe<cardType>
  outcome : attackOutcome
  income : int
 
pub type phaseResult
  IncomePhaseResult( incomes : list<int> )
  InvestPhaseResult( winner-name : maybe<string>, investments : list<int> )
  AttackPhaseResult( results : list<attackResult> )
  BuyPhaseResult( cards : list<maybe<cardType>>, conflicts : list<bool>, amts : list<int> )
  VictoryPhase

pub type playerMove
  Pass
  InvestMove( amt : int )
  AttackMove( idx : int )
  BuyMove( ty : cardType )

// TODO: Make player.kk?
pub effect getPlayerMove
  ctl get-move( state : gameState, idx : int ) : playerMove

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

pub struct stock
  card : cardType
  remaining : int

pub struct playerCard
  ty : cardType
  attacks : int
  defends : int

pub type playerStatus
  Playing
  Defeated
  Disqualified

pub fun playerStatus/show( s : playerStatus )
  match s
    Playing -> "playing"
    Defeated -> "defeated"
    Disqualified -> "disqualified"

pub struct player
  name : string
  status : playerStatus
  coins : int
  buys : int
  cards : list<playerCard>

pub struct gameState
  phase : phase
  day : day
  store : list<stock>
  players : list<player>

pub fun phase/show( p : phase )
  match p
    Income -> "INCOME"
    Invest -> "INVEST"
    Attack( _, _ ) -> "ATTACK"
    Buy -> "BUY"
    Victory -> "VICTORY"

pub fun int/day( i : int )
  match i
    1 -> One
    2 -> Two
    3 -> Three

pub fun day/show( d : day )
  match d
    One -> "1"
    Two -> "2"
    Three -> "3"

pub fun next-day( d : day ) : pure day
  match d
    One -> Two
    Two -> Three
    Three -> One

pub fun playerMove/invest( p : playerMove )
  match p
    Pass -> 0
    InvestMove( amt ) -> amt

pub fun playerMove/attack( p : playerMove )
  match p
    Pass -> Nothing
    AttackMove( idx ) -> Just( idx )

pub fun playerMove/buy( p : playerMove )
  match p
    Pass -> Nothing
    BuyMove( ty ) -> Just( ty )

pub fun phase/(==)( x : phase, y : phase ) : bool
  match x
    Income -> y.is-income
    Invest -> y.is-invest
    Attack( x-name, x-choice ) ->
      match y
        Attack( y-name, y-choice ) -> x-name == y-name && x-choice == y-choice
        _ -> False
    Buy -> y.is-buy
    Victory -> y.is-victory

pub fun phase/(!=)( x : phase, y : phase ) : bool
  !(x == y)

pub fun day/(==)( x : day, y : day ) : bool
  match x
    One -> y.is-one
    Two -> y.is-two
    Three -> y.is-three

pub fun day/(!=)( x : day, y : day ) : bool
  !(x == y)

pub fun stock/(==)( x : stock, y : stock ) : bool
  x.card == y.card && x.remaining == y.remaining

pub fun stock/(!=)( x : stock, y : stock ) : bool
  !(x == y)

pub fun playerStatus/(==)( x : playerStatus, y : playerStatus ) : bool
  match x
    Playing -> y.is-playing
    Defeated -> y.is-defeated
    Disqualified -> y.is-disqualified

pub fun playerStatus/(!=)( x : playerStatus, y : playerStatus ) : bool
  !(x == y)

pub fun cardType/(==)( x : cardType, y : cardType ) : bool
  match x
    SorcerersStipend -> y.is-sorcerersStipend
    Apprentice -> y.is-apprentice
    BoardOfMonopoly -> y.is-boardOfMonopoly
    Bubble -> y.is-bubble
    Ghost -> y.is-ghost
    GoldFish -> y.is-goldFish
    Golem -> y.is-golem
    Incantation -> y.is-incantation
    MagicBeanStock -> y.is-magicBeanStock
    SeniorWorker -> y.is-seniorWorker
    ShieldOfGreed -> y.is-shieldOfGreed
    Thug -> y.is-thug
    WallOfWealth -> y.is-wallOfWealth
    Worker -> y.is-worker

pub fun cardType/(!=)( x : cardType, y : cardType ) : bool
  !(x == y)

pub fun playerCard/(==)( x : playerCard, y : playerCard ) : bool
  if x.ty != y.ty then False
  else if x.attacks != y.attacks then False
  else if x.defends != y.defends then False
  else True

pub fun player/(==)( x : player, y : player ) : bool
  if x.name != y.name then False
  else if x.status != y.status then False
  else if x.coins != y.coins then False
  else if x.buys != y.buys then False
  else if x.cards.zip( y.cards ).any( fn( (x-c, y-c) ){ x-c != y-c }) then False
  else True

pub fun player/(!=)( x : player, y : player ) : bool
  !(x == y)

pub fun gameState/(==)( x : gameState, y : gameState ) : bool
  if x.phase != y.phase then False
  else if x.day != y.day then False
  else if x.store.length != y.store.length then False
  else if x.store.zip( y.store ).any( fn( (s-x, s-y) ){ s-x != s-y }) then False
  else if x.players.length != y.players.length then False
  else if x.players.zip( y.players ).any( fn( (p-x, p-y) ){ p-x != p-y }) then False
  else True

pub fun gameState/(!=)( x : gameState, y : gameState )
  !(x == y)
