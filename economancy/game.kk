pub type phase
  Income
  Invest
  Attack
  Buy
  Victory

pub fun phase/show( p : phase )
  match p
    Income -> "INCOME"
    Invest -> "INVEST"
    Attack -> "ATTACK"
    Buy -> "BUY"
    Victory -> "VICTORY"

// TODO: This is specific to the assignment's API, and should probably be in its own module.
pub fun string/phase( p : string )
  match p
    "income" -> Income
    "investing" -> Invest
    "attacking" -> Attack
    "buy" -> Buy
    "end" -> Victory

pub type day
  One
  Two
  Three

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

fun next-day( d : day ) : pure day
  match d
    One -> Two
    Two -> Three
    Three -> One

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

pub fun string/cardType( s : string )
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

pub fun cardType/show( ty : cardType )
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

pub fun cardType/(==)( x : cardType, y : cardType )
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

fun get-card-stats( ty : cardType ) : pure (int, int)
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

fun get-card-victory-points( ty : cardType ) : pure int
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

pub struct stock
  card : cardType
  remaining : int

pub fun stock/show( s : stock )
  "Type: " ++ s.card.show ++ " Remaining: " ++ s.remaining.show

pub struct playerCard
  ty : cardType
  attacks : int
  defends : int

pub fun playerCard/show( p : playerCard )
  "Type: " ++ p.ty.show ++ " Attacks: " ++ p.attacks.show ++ " Defends: " ++ p.defends.show
  
pub type playerStatus
  Playing
  Defeated

pub struct player
  name : string
  status : playerStatus
  coins : int
  buys : int
  cards : list<playerCard>

// TODO: The tabs here are hard-coded to show players when printing game state.
pub fun player/show( p : player )
  "Name: " ++ p.name ++ 
  "\n\t\tCoins: " ++ p.coins.show ++ 
  "\n\t\tBuys: " ++ p.buys.show ++ 
  "\n\t\tCards: " ++ p.cards.show

pub struct gameState
  phase : phase
  day : day
  store : list<stock>
  players : list<player>
  attacker-name : maybe<string>
  attacker-card : maybe<int>

pub fun gameState/show( s : gameState )
  val attacker-str = match s.attacker-name
    Nothing -> "NONE"
    Just( n ) -> n

  "Phase: " ++ s.phase.show ++ 
    "\n\tDay: " ++ s.day.show ++ 
    "\n\tStore:\n\t\t" ++ s.store.map( show ).join( "\n\t\t" ) ++
    "\n\tPlayers:\n\t\t" ++ s.players.map( show ).join( "\n\t\t" ) ++
    "\n\tAttacker: " ++ attacker-str

fun get-player( game-state : gameState, player-name : string )
  game-state.players.find( fn( p ){ p.name == player-name }).unjust

fun get-player-card( game-state : gameState, player-name : string, card-idx : int )
  game-state.get-player( player-name ).cards[card-idx].unjust

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

pub fun get-stock-count( store : list<stock>, p : cardType ) : pure int
  store.find( fn(x){ x.card == p } ).unjust.remaining

fun remove-purchase( store : list<stock>, p : cardType, new-store : list<stock> = [] ) : pure list<stock>
  match store
    Nil -> new-store
    Cons( x, xs ) ->
      if x.card == p then
        new-store ++ [x( remaining = [x.remaining - 1, 0].maximum )] ++ xs
      else
        remove-purchase( xs, p, new-store ++ [x])

fun remove-purchases( store : list<stock>, purchases : list<cardType> ) : pure list<stock>
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
  GameState( Income, One, stock, players, Nothing, Nothing )

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

pub fun get-victory-points( p : player ) : pure int
  p.cards.map( fn(c){ c.ty.get-card-victory-points } ).sum

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

pub type playerMove
  Pass
  InvestMove( amt : int )
  AttackMove( idx : int )
  BuyMove( ty : cardType )

// TODO: We can probably match directly instead of converting them to maybes

fun playerMove/invest( p : playerMove )
  match p
    Pass -> 0
    InvestMove( amt ) -> amt

fun playerMove/attack( p : playerMove )
  match p
    Pass -> Nothing
    AttackMove( idx ) -> Just( idx )

fun playerMove/buy( p : playerMove )
  match p
    Pass -> Nothing
    BuyMove( ty ) -> Just( ty )

effect getPlayerMove
  ctl get-move( state : gameState, idx : int ) : playerMove

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
 
pub type phaseResult
  IncomePhaseResult( incomes : list<int> )
  InvestPhaseResult( winner-name : maybe<string>, investments : list<int> )
  AttackPhaseResult( results : list<attackResult> )
  BuyPhaseResult( cards : list<maybe<cardType>>, conflicts : list<bool>, amts : list<int> )
  VictoryPhase

pub fun resolve-current-phase( state : gameState ) : <pure, getPlayerMove> (gameState, phaseResult)
  val resolve-fn = match state.phase
    Income -> resolve-income
    Invest -> resolve-invest
    Attack -> resolve-attack
    Buy -> resolve-buy
    Victory -> fn( state ){ (state, VictoryPhase) }

  resolve-fn( state )

// TODO: Only get player moves if they aren't defeated

fun resolve-income( state : gameState ) : <pure> (gameState, phaseResult)
  val incomes = state.players.map( fn( p ){ get-player-income( state.day, p, 0, p.cards )} )
  val buys = state.players.map( fn( p ){ get-player-buys( state.day, p )})
  val cards = state.players.map( fn( p ){ p.cards.map( fn( c ){ get-card-attacks-defends( c.ty ) })})
  val new-players = state.players.zip( incomes ).zip( buys ).zip( cards ).map( fn( (((p,i),b),c) ){ p( coins = p.coins + i, buys = b, cards = c ) })
  val new-state = state( phase = Invest, players = new-players )
  (new-state, IncomePhaseResult( incomes ))

fun resolve-invest( state : gameState ) : <pure,getPlayerMove> (gameState, phaseResult)
  val players-and-invests = state.players.map-indexed( fn(i,p){ (p, get-move( state, i ).invest) })
  val new-players = players-and-invests.map( fn( (p,i) ) { p( coins = p.coins - i) })

  val player-invests = players-and-invests.map( fn( (_,i) ){ i })
  val max-invest = player-invests.maximum
  val max-count = player-invests.foldl( 0, fn(c, i){ if i == max-invest then c + 1 else c })

  // If all investments are the same, there is no winner
  if max-count > 1 then
    (state( phase = Buy, players = new-players ), InvestPhaseResult( Nothing, player-invests ))
  // Otherwise, the player with the maximum investment wins
  else
    val (winner,_) = players-and-invests.find( fn( (p, i) ){ i == max-invest } ).unjust
    val winner-name = winner.player/name

    (state( phase = Attack, players = new-players, attacker-name = Just( winner-name ) ),
      InvestPhaseResult( Just( winner-name ), player-invests ) )
 
fun drop-idx( xs : list<a>, idx : int ) : pure list<a>
  list(0, xs.length - 1).zip( xs ).filter( fn( (i,x) ){ i != idx } ).map( fn( (_,x) ){ x })

fun resolve-outcome( x : maybe<cardType>, y : maybe<cardType> ) : pure attackOutcome
  match y
    Nothing -> CardOkay
    Just( y-ty ) ->
      // Player didn't supply a card and is defeated
      match x
        Nothing -> PlayerDefeated
        Just( x-ty ) ->
          val (_, x-defense) = x-ty.get-card-stats()
          val (y-attack, _) = y-ty.get-card-stats()
          if y-attack > x-defense then CardFainted else CardOkay

// TODO: Add coins to players when shield of greed defends
fun resolve-attack( state : gameState ) : <pure,getPlayerMove> (gameState, phaseResult)
  val attacker-name = match state.attacker-name
    Just( s ) -> s

  val attacker-idx = state.players.index-of( fn( p ){ p.name == attacker-name } )
  val attacker-move = get-move( state, attacker-idx ).attack
  val state-with-attack = state( attacker-card = attacker-move )

  fun get-choice-ty( player-idx, card-idx )
    match card-idx
      Nothing -> Nothing
      Just( i ) -> Just( state.players[player-idx].unjust.cards[i].unjust.ty )

  val attacker-choice = get-choice-ty( attacker-idx, attacker-move )
  
  val defender-idxs = list(0, state.players.length - 1).filter( fn(i){ i != attacker-idx } )
  val defender-moves = defender-idxs.map( fn(i){ get-move( state-with-attack, i).attack } )
  val defender-choices = defender-idxs.zip( defender-moves ).map( fn( (i,m) ){ get-choice-ty( i, m ) })

  val all-moves = defender-moves.take( attacker-idx ) ++ [attacker-move] ++ defender-moves.drop( attacker-idx )
  val all-choices = defender-choices.take( attacker-idx ) ++ [attacker-choice] ++ defender-choices.drop( attacker-idx )

  fun resolve-outcomes( attacker-idx : int, curr-idx : int, outcomes : list<attackOutcome> )
    if curr-idx >= state.players.length then outcomes
    else if curr-idx == attacker-idx then
      val attacker-outcomes = defender-choices.map( fn( c ){ resolve-outcome( attacker-choice, c )})
      val attacker-outcome = if attacker-outcomes.any( is-cardFainted ) then CardFainted else CardOkay
      resolve-outcomes( attacker-idx, curr-idx + 1, outcomes ++ [attacker-outcome])
    else
      val defender-choice = all-choices[curr-idx].unjust
      val outcome = resolve-outcome( defender-choice, attacker-choice )
      resolve-outcomes( attacker-idx, curr-idx + 1, outcomes ++ [outcome])

  val outcomes = resolve-outcomes( attacker-idx, 0, [] )
  
  // Update players' cards' attacks and defends
  fun update-card-attacks( role : attackRole, p : player, card-idx-maybe : maybe<int> )
    match card-idx-maybe
      Nothing -> p
      Just( card-idx ) ->
        val new-cards = p.cards.map-indexed( fn( i, c){
          if i != card-idx then c
          else
            match role
              Attacker -> c( attacks = [c.attacks - 1, 0].maximum)
              Defender -> c( defends = [c.defends - 1, 0].maximum)
        })
        p( cards = new-cards )

  fun remove-fainted-cards( p : player, o : attackOutcome, card-idx-maybe : maybe<int> )
    match o
      CardFainted ->
        match card-idx-maybe
          Just( idx ) ->
            val new-cards = p.cards.drop-idx( idx )
            p( cards = new-cards )
          _ -> p
      _ -> p

  fun get-role( p : player )
    if p.name == attacker-name then Attacker
    else Defender

  val results = state.players.zip( all-choices ).zip( outcomes ).map( fn( ((p,c),o) ){ AttackResult(p.name, get-role( p ), c, o)} )

  val players-attacks-updated = state.players.zip( all-moves ).map( fn( (p,c) ){ update-card-attacks( get-role( p ), p, c) })
  val players-faints-updated = players-attacks-updated.zip( outcomes ).zip( all-moves ).map( fn( ((p,o),c) ){ remove-fainted-cards( p, o, c )})
  val remaining-players = players-faints-updated.zip( outcomes ).map( fn( (p,o) ){ if o.is-playerDefeated then p( status = Defeated ) else p })

  // Determine phase. Phase is attack if the attacking player has cards with
  // remaining attacks OR the attacker has passed.
  val num-remaining-players = remaining-players.filter( fn(p){ p.status.is-playing } ).length
  val new-phase = if num-remaining-players == 1 then
    Victory
  else
    match attacker-choice
      Nothing -> Buy
      _ ->
        val has-attacks = players-attacks-updated[attacker-idx].unjust.cards.any( fn(c){ c.attacks > 0 })
        if has-attacks then Attack else Buy

  val new-attacker-name = if new-phase.is-attack then Just( attacker-name ) else Nothing

  (state( phase = new-phase, players = remaining-players, attacker-name = new-attacker-name, attacker-card = Nothing ), AttackPhaseResult( results ))


fun resolve-buy( state : gameState ) : <pure,getPlayerMove> (gameState, phaseResult)
  val buy-choices = state.players.map-indexed( fn(i,p){
    if p.status.is-defeated then Nothing
    else get-move( state, i ).buy
  })

  val players-decremented-buys = state.players.map( fn(p){ p( buys = [p.buys - 1, 0].maximum)})

  val bought-card-tys = buy-choices.filter( is-just ).map( unjust )

  // Resolve all buys
  fun resolve-player-buy( buy : maybe<cardType> )
    match buy
      Nothing -> Nothing
      Just( card-ty ) ->
        // If there are fewer cards available than the total buys, players get nothing
        val num-buys = bought-card-tys.filter( fn(ty : cardType){ ty == card-ty }).length
        if num-buys >= state.store.get-stock-count( card-ty ) then Nothing
        else
          Just( card-ty )

  val buy-results = buy-choices.map( resolve-player-buy )
  val purchase-conflicts = buy-results.map( fn(x){ if x.is-just then False else True})
  val purchase-amts = buy-choices.map( fn(x){ 
    match x
      Nothing -> 0
      Just( c ) -> c.get-price
  })

  // Update players
  val players-updated = state.players.zip( buy-results ).zip( purchase-amts ).map( fn( ((p,r),a) ){ 
      val new-num-buys = [p.buys - 1, 0].maximum
      val new-coins = p.coins - a

      val new-cards = match r
        Nothing -> p.cards
        Just( ty ) -> p.cards ++ [PlayerCard( ty, 0, 0 )]

      p( buys = new-num-buys, cards = new-cards, coins = new-coins) 
  })

  val new-store = state.store.remove-purchases( bought-card-tys )

  // Players can win here if:
  // - At least one player has 7+ victory points (player with most points wins)
  // - If multiple players have 7+ and they are the same, play continues
  // - TODO: (DRAW) Stock is exhausted and players can't eliminate each other
  val victory-points = players-updated.map( fn(p){ p.get-victory-points })
  val max-points = victory-points.maximum
  val num-max = victory-points.filter( fn(p){ p == max-points }).length
  val has-victor = max-points > 7 && num-max == 1
  val players-with-victor = if has-victor then 
    players-updated.map( fn(p){ if p.get-victory-points == max-points then p else p( status = Defeated ) } ) 
  else players-updated

  val next-phase = if has-victor then Victory
    else if players-updated.any( fn(x){ x.buys > 0 }) then Buy 
    else Income
  val next-day = if next-phase.is-buy then state.day else state.day.next-day

  val result = BuyPhaseResult( buy-choices, purchase-conflicts, purchase-amts )

  (state( phase = next-phase, day = next-day, store = new-store, players = players-with-victor), result)