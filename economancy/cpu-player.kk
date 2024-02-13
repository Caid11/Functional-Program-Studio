import game

pub fun get-invest( game-state : gameState, player-name : string ) : pure int
  0

pub fun get-attack( game-state : gameState, player-name : string ) : pure maybe<int>
  Nothing

pub fun get-buy( game-state : gameState, player-name : string ) : pure maybe<cardType>
  Nothing