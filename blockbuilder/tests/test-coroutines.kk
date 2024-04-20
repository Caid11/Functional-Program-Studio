module tests/test-coroutines

import coroutine

import tests/test

struct simpleState
  to-avg : list<int>
  num-to-avg : int
  avg : int

fun test-simple-coroutine()
  val test-nums = [1,2,3,4,5,6]
  
  val init-state = SimpleState(test-nums, test-nums.length, 0)

  val avg-ops = [
    fn(state : simpleState){
      match state.to-avg
        Nil -> state(avg = state.avg / state.num-to-avg)
        Cons(x, xs) ->
          val new-sum = state.avg + x
          yield(state(to-avg = xs, avg = new-sum))
    }
  ]

  val avg-coro = Coroutine(init-state, avg-ops)

  fun run-coro-until-finished(c : coroutine<simpleState>)
    val new-c = c.coresume()
    match new-c.ops
      Nil -> new-c.state.avg
      _ -> new-c.run-coro-until-finished()

  val coro-avg = avg-coro.run-coro-until-finished()

  val avg = test-nums.sum / test-nums.length
  if coro-avg != avg then
    test-fail("Bad result from coroutine: " ++ coro-avg.show)
  else ()

val simple-coro-test = Test(
  "simple-coro-test",
  test-simple-coroutine
)

pub val coroutine-tests = Case(
  "coroutine",
  [
    simple-coro-test
  ]
)