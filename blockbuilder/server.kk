module server

import commands

pub type server
  LocalServer
  RemoteServer(addr : string)

pub fun get-cmds(s : server) : list<command>
  // TODO
  []

pub fun submit-cmds(s : server, cmds : list<command>) : ()
  // TODO
  ()

pub fun broadcast-cmds(s : server) : ()
  // TODO
  ()