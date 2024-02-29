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

