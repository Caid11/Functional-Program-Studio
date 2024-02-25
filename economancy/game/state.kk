module game/state

import game/card
import game/types

pub fun stock/show( s : stock )
  "Type: " ++ s.card.show ++ " Remaining: " ++ s.remaining.show

pub fun playerCard/show( p : playerCard )
  "Type: " ++ p.ty.show ++ " Attacks: " ++ p.attacks.show ++ " Defends: " ++ p.defends.show
  
// TODO: The tabs here are hard-coded to show players when printing game state.
pub fun player/show( p : player )
  "Name: " ++ p.name ++ 
  "\n\t\tCoins: " ++ p.coins.show ++ 
  "\n\t\tBuys: " ++ p.buys.show ++ 
  "\n\t\tCards: " ++ p.cards.show

pub fun gameState/show( s : gameState )
  val attacker-str = match s.phase
    Attack( name, _ ) -> name
    _ -> "NONE"

  "Phase: " ++ s.phase.show ++ 
    "\n\tDay: " ++ s.day.show ++ 
    "\n\tStore:\n\t\t" ++ s.store.map( show ).join( "\n\t\t" ) ++
    "\n\tPlayers:\n\t\t" ++ s.players.map( show ).join( "\n\t\t" ) ++
    "\n\tAttacker: " ++ attacker-str

pub fun get-player( game-state : gameState, player-name : string )
  game-state.players.find( fn( p ){ p.name == player-name }).unjust

pub fun get-player-card( game-state : gameState, player-name : string, card-idx : int )
  game-state.get-player( player-name ).cards[card-idx].unjust

pub fun get-init-stock( num-players : int ) : pure list<stock>
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

pub fun get-stock-count( store : list<stock>, p : cardType ) : pure int
  store.find( fn(x){ x.card == p } ).unjust.remaining

pub fun remove-purchase( store : list<stock>, p : cardType, new-store : list<stock> = [] ) : pure list<stock>
  match store
    Nil -> new-store
    Cons( x, xs ) ->
      if x.card == p then
        new-store ++ [x( remaining = [x.remaining - 1, 0].maximum )] ++ xs
      else
        remove-purchase( xs, p, new-store ++ [x])

pub fun remove-purchases( store : list<stock>, purchases : list<cardType> ) : pure list<stock>
  match purchases
    Nil -> store
    Cons( p, ps ) -> remove-purchases( remove-purchase( store, p ), ps )

pub fun get-init-state( player-names : list<string> )
  val players = player-names.map( fn( name ){
    Player(name,
           Playing,
           0, 
           0, 
           [PlayerCard(SorcerersStipend, 0, 0)])
  })
    
  val stock = get-init-stock( player-names.length )
  GameState( Income, One, stock, players )

