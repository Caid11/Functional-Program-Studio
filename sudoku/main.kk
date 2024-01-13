import std/os/file
import std/os/path

import sort

ref type cell
  Empty
  Number( n : int )

fun show-cell( c : cell ) : string
  match c
    Empty -> "   |"
    Number(num) -> " " ++ num.show ++ " |"

fun show-puzzle( p : list<cell>)
  fun show-puzzle-r( pr : list<cell>, i : int)
    if i >= p.length then ()
    else
      match pr[i]
        Just(cell) ->
          print(cell.show-cell)
          if (i + 1) %  9 == 0 then
            println("")
          else
            print("")
          show-puzzle-r(p, i + 1)
  show-puzzle-r(p, 0)

fun parse( txt : string, acc : list<cell>, curr : string )
  match txt.head-char
    Nothing -> acc
    Just(' ') -> parse(txt.slice.drop(1).string, acc, curr)
    Just('\n') -> parse(txt.slice.drop(1).string, acc, curr)
    Just('|') -> 
      match curr.parse-int
        Nothing -> parse(txt.slice.drop(1).string, acc ++ [Empty], "")
        Just(num) -> parse(txt.slice.drop(1).string, acc ++ [Number(num)], "")
    Just(num) -> parse(txt.slice.drop(1).string, acc, curr ++ num.string)

fun elim-dups(l)
  fun accum-if-diff(acc : list<int>, x : int)
    match acc
      Nil -> [x]
      Cons(y, _) ->
        if x != y then
          Cons(x, acc)
        else
          acc
  l.msort.foldl([], accum-if-diff)

fun all-unique(l : list<int>)
  elim-dups(l).length == l.length

fun collect-col(p : list<cell>, i : int)
  fun collect-col-r(idx, acc)
    match p[idx]
      Nothing -> acc
      Just(cell) ->
        if idx % 9 != i % 9 then
          collect-col-r(idx + 1, acc)
        else
          match cell
            Empty -> collect-col-r(idx + 1, acc)
            Number(num) -> collect-col-r(idx + 1, acc ++ [num])
  collect-col-r(0, [])

fun collect-row(p : list<cell>, i : int)
  var low-idx := i / 9 * 9
  var hi-idx := low-idx + 9
  fun collect-row-r(idx, acc)
    if idx >= hi-idx then acc
    else
      match p[idx]
        Just(cell) ->
          match cell
            Empty -> collect-row-r(idx + 1, acc)
            Number(num) -> collect-row-r(idx + 1, acc ++ [num])
  collect-row-r(low-idx, [])

fun collect-grid(p : list<cell>, i : int)
  var col-offset := i % 9
  var col-lo := col-offset / 3 * 3
  var col-hi := col-lo + 3

  var row-offset := i / 9
  var row-lo := row-offset / 3 * 3
  var row-hi := row-lo + 3

  fun get-cell(row, col)
    var idx := row * 9 + col
    p[idx]

  fun collect-grid-r(row, col, acc)
    if row >= row-hi then acc
    else if col >= col-hi then collect-grid-r(row + 1, col-lo, acc)
    else
      match get-cell(row, col)
        Just(cell) ->
          match cell
            Empty -> collect-grid-r(row, col + 1, acc)
            Number(num) -> collect-grid-r(row, col + 1, acc ++ [num])
  
  collect-grid-r(row-lo, col-lo, [])

fun is-legal( p : list<cell>, i : int )
  all-unique(collect-col(p, i)) && all-unique(collect-row(p, i)) && all-unique(collect-grid(p, i))

fun is-legal-all( p : list<cell> )
  fun is-legal-all-r( idx )
    if idx >= 81 then True
    else
      all-unique(collect-col(p, idx)) && all-unique(collect-row(p, idx)) && all-unique(collect-grid(p, idx)) && is-legal-all-r(idx + 1)
  
  is-legal-all-r( 0 )

fun solve( p : list<cell> )
  fun solve-r( pr : list<cell>, idx )
    fun solve-cell( pc : list<cell>, cell-idx : int, num : int )
      if num > 9 then Nothing
      else
        val puz-with-num = pc.take(cell-idx) ++ [Number(num)] ++ pc.drop(cell-idx + 1)
        match solve-r( puz-with-num, cell-idx + 1 )
          Nothing -> solve-cell( pc, cell-idx, num + 1 )
          Just( puz ) -> Just( puz )

    if idx >= 81 then Just( pr )
    else if !is-legal-all(pr) then Nothing
    else
      match pr[idx]
        Just(cell) ->
          match cell
            Number(_) -> solve-r( pr, idx + 1 )
            Empty -> solve-cell( pr, idx, 1 )

  solve-r( p, 0 )

fun main()
  var txt := read-text-file("simple.txt".path)
  var puzzle := parse(txt, [], "")
  println(puzzle.show-puzzle)
  println("")

  match solve(puzzle)
    Nothing -> println("Unsolvable")
    Just(puz) -> println(puz.show-puzzle)
  ()