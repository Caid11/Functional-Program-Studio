module game/card

import game/types

pub fun cardType( s : string )
  match s
    "Sorcerer's Stipend" -> SorcerersStipend
    "Apprentice" -> Apprentice
    "Board of Monopoly" -> BoardOfMonopoly
    "Bubble" -> Bubble
    "Ghost" -> Ghost
    "Gold Fish" -> GoldFish
    "Golem" -> Golem
    "Incantation" -> Incantation
    "Magic Bean Stock" -> MagicBeanStock
    "Senior Worker" -> SeniorWorker
    "Shield of Greed" -> ShieldOfGreed
    "Thug" -> Thug
    "Wall of Wealth" -> WallOfWealth
    "Worker" -> Worker

pub fun show( ty : cardType )
  match ty
    SorcerersStipend -> "Sorcerer's Stipend"
    Apprentice -> "Apprentice"
    BoardOfMonopoly -> "Board of Monopoly"
    Bubble -> "Bubble"
    Ghost -> "Ghost"
    GoldFish -> "Gold Fish"
    Golem -> "Golem"
    Incantation -> "Incantation"
    MagicBeanStock -> "Magic Bean Stock"
    SeniorWorker -> "Senior Worker"
    ShieldOfGreed -> "Shield of Greed"
    Thug -> "Thug"
    WallOfWealth -> "Wall of Wealth"
    Worker -> "Worker"

pub fun get-price( ty : cardType ) : pure int
  match ty
    Apprentice -> 3
    BoardOfMonopoly -> 2
    Bubble -> 2
    Ghost -> 2 
    GoldFish -> 3
    Golem -> 5
    Incantation -> 4 
    MagicBeanStock -> 1
    SeniorWorker -> 2
    ShieldOfGreed -> 4
    Thug -> 3
    WallOfWealth -> 1
    Worker -> 1

pub fun get-card-stats( ty : cardType ) : pure (int, int)
  match ty
    Apprentice -> (2,1)
    BoardOfMonopoly -> (1,1)
    Bubble -> (9,2)
    Ghost -> (3,2) 
    GoldFish -> (1,2)
    Golem -> (7,7)
    Incantation -> (1,1) 
    MagicBeanStock -> (1,1)
    SeniorWorker -> (2,2)
    ShieldOfGreed -> (2,7)
    Thug -> (4,4)
    WallOfWealth -> (1,2)
    Worker -> (1,2)

pub fun get-card-victory-points( ty : cardType ) : pure int
  match ty
    SorcerersStipend -> 0
    Apprentice -> 0
    BoardOfMonopoly -> 1
    Bubble -> 0
    Ghost -> 0
    GoldFish -> 0
    Golem -> 0
    Incantation -> 3
    MagicBeanStock -> 0
    SeniorWorker -> 0
    ShieldOfGreed -> 0
    Thug -> 0
    WallOfWealth -> 0
    Worker -> 0

pub fun get-card-income( player-coins : int, card : cardType, d : day )
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

pub fun get-card-buys( c : cardType, d : day ) : pure int
  match c
    Apprentice ->
      match d
        Three -> 1
        _ -> 0
    _ -> 0

// TODO: Merge attacks and defends, have this function call get-[attacks|defends] and take is-attacker param.
pub fun get-card-attacks-defends( c : cardType ) : pure playerCard
  match c
    SorcerersStipend -> PlayerCard( c, 0, 0 )
    Bubble -> PlayerCard( c, 0, 1 )
    WallOfWealth -> PlayerCard( c, 1, 2 )
    _ -> PlayerCard( c, 1, 1 )