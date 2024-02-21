import cpu-player

pub type playerType
  Human
  Cpu( strat : strategy )

pub struct playerInitInfo
  name : string
  ty : playerType