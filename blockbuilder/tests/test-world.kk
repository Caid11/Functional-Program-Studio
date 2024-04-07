module tests/test-world

import world
import tests/test

import std/num/float64

// fun world-rotates()
//   val world = GameWorld(0.0)
//   val expected = GameWorld(0.0 + 0.01)
// 
//   Test(
//     "rotates",
//     fn(){
//       val updated = world.tick
//       val is-success = updated == expected
//       if is-success then Success
//       else Fail(expected-actual-msg(expected.show, updated.show))
//     })

pub val world-tests = Case(
  "world",
  [
    // world-rotates()
  ]
)