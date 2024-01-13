fun merge( l : list<int>, r : list<int> ) : list<int>
  match l
    Nil -> r
    Cons(x, xs) ->
      match r
        Nil -> l
        Cons(y, ys) ->
          if x < y then
            Cons(x, merge(xs, r))
          else
            Cons(y, merge(l, ys))


fun msort( p : list<int> ) : <div|_e> list<int>
  if p.length == 0 then
    p
  else if p.length == 1 then
    p
  else
    val l = p.take(p.length / 2)
    val r = p.drop(p.length / 2)
    merge(msort(l), msort(r))

// fun main()
//   var l := [5, 2, 3]
//   println(msort(l).show)
//   var r := []
//   println(msort(r).show)
//   var x := [0]
//   println(msort(x).show)