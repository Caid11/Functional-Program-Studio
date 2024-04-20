module coroutine

pub effect<a> ctl yield(x : a) : b // Resume should be handled via coresume

pub struct coroutine<a>
  state : a
  ops : list<(a -> yield<a> a)>

pub fun coresume(c : coroutine<a>) : _e coroutine<a>
  with ctl yield(state) c(state = state)
  // c
  match c.ops
    Nil -> c
    Cons(x, xs) ->
      val new-state = x(c.state)
      mask<yield>
        coresume(c(ops = xs, state = new-state))

// struct playerIdRequest
//   sock : socket
//   player-id : int
//   pos : vector3
// 
// fun yield-if-not-readable(state : playerIdRequest)
//   if !select([state.sock], [], [], False).is-readable(state.sock) then
//     yield(state)
//   else
//     ()
// 
// 
// fun make-net-request(s)
//   val state = PlayerIdRequest(s, -1, Vector3(0.0, 0.0, 0.0))
// 
//   val ops = [
//     fn(state : playerIdRequest){ 
//       state.yield-if-not-readable
//       
//       val player-id : int= state.sock.recv()
//       state(player-id = player-id)
//     },
//   ]
// 
//   Coroutine(state, ops)