module game/resolve

import game/types
import game/card
import game/state

fun get-player-income( d : day, p : player, coins : int, cards : list<playerCard> ) : pure int
  match cards
    Nil -> coins
    Cons( c, cs ) -> get-player-income( d, p, coins + get-card-income( coins, c.ty, d ), cs)

pub fun get-victory-points( p : player ) : pure int
  p.cards.map( fn(c){ c.ty.get-card-victory-points } ).sum

fun get-player-buys( d : day, p : player ) : pure int
  val card-buys = p.cards.map( fn( c ){ get-card-buys( c.ty, d )}).sum
  card-buys + 1

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

    (state( phase = Attack( winner-name, Nothing ), players = new-players ),
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
  val attacker-name = match state.phase
    Attack( name, _ ) -> name

  val attacker-idx = state.players.index-of( fn( p ){ p.name == attacker-name } )
  val attacker-move = get-move( state, attacker-idx ).attack

  val attack-with-move = Attack( attacker-name, attacker-move )
  val state-with-attack = state( phase = attack-with-move )

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

  val results = state.players.zip( all-choices ).zip( outcomes ).map( fn( ((p,c),o) ){
    val income = match get-role( p )
      Attacker -> 0
      Defender ->
        match c
          Just( ShieldOfGreed ) -> 1
          _ -> 0
      
    AttackResult(p.name, get-role( p ), c, o, income)
  })

  val players-attacks-updated = state.players.zip( all-moves ).map( fn( (p,c) ){ update-card-attacks( get-role( p ), p, c) })
  val players-coins-updated = players-attacks-updated.zip( results ).map( fn( (p,r) ){ p( coins = p.coins + r.income )})
  val players-faints-updated = players-coins-updated.zip( outcomes ).zip( all-moves ).map( fn( ((p,o),c) ){ remove-fainted-cards( p, o, c )})
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
        if has-attacks then Attack( attacker-name, Nothing ) else Buy

  val new-attacker-name = if new-phase.is-attack then Just( attacker-name ) else Nothing

  (state( phase = new-phase, players = remaining-players ), AttackPhaseResult( results ))


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