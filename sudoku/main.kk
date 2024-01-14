import std/os/file
import std/os/path

import sort

ref type cell
  Empty
  Number( n : int )

struct puzzle
  num-grids-high : int
  num-grids-wide : int
  cells : list<cell>

fun row-width( p : puzzle ) : int
  p.num-grids-wide * p.num-grids-high

fun col-height( p : puzzle ) : int
  p.num-grids-high * p.num-grids-wide

fun num-grid-cells( p : puzzle ) : int
  p.num-grids-high * p.num-grids-wide

fun num-cells( p : puzzle ) : int
  p.row-width * p.col-height

fun collect-col(p : puzzle, cell-idx : int)
  fun col-offset(idx : int)
    idx % p.row-width

  fun collect-col-r(idx, acc)
    match p.cells[idx]
      Nothing -> acc
      Just(cell) ->
        if idx.col-offset != cell-idx.col-offset then
          collect-col-r(idx + 1, acc)
        else
          match cell
            Empty -> collect-col-r(idx + 1, acc)
            Number(num) -> collect-col-r(idx + 1, acc ++ [num])
  
  collect-col-r(0, [])

fun collect-row(p : puzzle, cell-idx : int)
  var low-idx := cell-idx / p.row-width * p.row-width
  var hi-idx := low-idx + p.row-width

  fun collect-row-r(idx, acc)
    if idx >= hi-idx then acc
    else
      match p.cells[idx]
        Just(cell) ->
          match cell
            Empty -> collect-row-r(idx + 1, acc)
            Number(num) -> collect-row-r(idx + 1, acc ++ [num])
  collect-row-r(low-idx, [])

fun collect-grid(p : puzzle, cell-idx : int)
  var col-offset := cell-idx % p.row-width
  var col-lo := col-offset / p.num-grids-high * p.num-grids-high
  var col-hi := col-lo + p.num-grids-high

  var row-offset := cell-idx / p.row-width
  var row-lo := row-offset / p.num-grids-wide * p.num-grids-wide
  var row-hi := row-lo + p.num-grids-wide

  fun get-cell(row, col)
    var idx := row * p.row-width + col
    p.cells[idx]

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

// Puzzle TXT file parsing

fun parse( txt : string )
  fun parse-cells( num-grids-high : int, num-grids-wide : int, txt-slc : sslice, num-str : string, acc : list<cell> )
    match txt-slc.take(1).string
      "" -> Puzzle( num-grids-high, num-grids-wide, acc)
      " " -> parse-cells( num-grids-high, num-grids-wide, txt-slc.advance(1), num-str, acc)
      "\n" -> 
        parse-cells( num-grids-high, num-grids-wide, txt-slc.advance(1), num-str, acc)

      "|" ->
        if num-str.is-empty then parse-cells( num-grids-high, num-grids-wide, txt-slc.advance(1), "", acc ++ [Empty])
        else
          match num-str.parse-int
            Just(num) -> parse-cells( num-grids-high, num-grids-wide, txt-slc.advance(1), "", acc ++ [Number(num)] )

      str -> parse-cells( num-grids-high, num-grids-wide, txt-slc.advance(1), num-str ++ str, acc)

  fun parse-grids-wide( num-grids-high : int, txt-slc : sslice, num-str : string)
    match txt-slc.take(1).string
      "" -> throw("Unexpected EOF when parsing grid width")
      "\n" ->
        match num-str.parse-int
          Just(num) -> parse-cells(num-grids-high, num, txt-slc.advance(1), "", [])
      str -> parse-grids-wide( num-grids-high, txt-slc.advance(1), num-str ++ str)

  fun parse-grids-high( txt-slc : sslice, num-str : string )
    match txt-slc.take(1).string
      "" -> throw("Unexpected EOF when parsing grid height")
      " " ->
        match num-str.parse-int
          Just(num) -> parse-grids-wide(num, txt-slc.advance(1), "")
      str -> parse-grids-high(txt-slc.advance(1), num-str ++ str)

  parse-grids-high(txt.slice, "")

// Print parsed puzzle

fun show-cell( c : cell ) : string
  match c
    Empty -> "   |"
    Number(num) -> " " ++ num.show ++ " |"

fun show-cells( row-width : int, c : list<cell>, i : int )
  if i >= c.length then ()
  else
    match c[i]
      Just(cell) ->
        print(cell.show-cell)
        if (i + 1) %  row-width == 0 then
          println("")
        else
          print("")
        show-cells( row-width, c, i + 1)

fun show-puzzle( p : puzzle )
  println(p.num-grids-high.show ++ " " ++ p.num-grids-wide.show)
  show-cells(p.num-grids-high * p.num-grids-wide, p.cells, 0)

// List utility methods

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

// Puzzle solving 

fun is-legal( p : puzzle, i : int )
  all-unique(collect-col(p, i)) && all-unique(collect-row(p, i)) && all-unique(collect-grid(p, i))

fun is-legal-all( p : puzzle )
  fun is-legal-all-r( idx )
    if idx >= p.num-cells then True
    else
      all-unique(collect-col(p, idx)) && all-unique(collect-row(p, idx)) && all-unique(collect-grid(p, idx)) && is-legal-all-r(idx + 1)
  
  is-legal-all-r( 0 )

fun solve( p : puzzle )
  fun solve-r( pr : puzzle, idx )
    fun solve-cell( pc : puzzle, cell-idx : int, num : int )
      if num > pc.num-grid-cells then Nothing
      else
        val puz-with-num = Puzzle(pc.num-grids-high, pc.num-grids-wide, pc.cells.take(cell-idx) ++ [Number(num)] ++ pc.cells.drop(cell-idx + 1))
        match solve-r( puz-with-num, cell-idx + 1 )
          Nothing -> solve-cell( pc, cell-idx, num + 1 )
          Just( puz ) -> Just( puz )

    if !is-legal-all(pr) then Nothing
    else if idx >= p.num-cells then Just( pr )
    else
      match pr.cells[idx]
        Just(cell) ->
          match cell
            Number(_) -> solve-r( pr, idx + 1 )
            Empty -> solve-cell( pr, idx, 1 )

  solve-r( p, 0 )

fun main()
  var txt := read-text-file("3x2.txt".path)
  var puzzle := parse(txt)
  println(puzzle.show-puzzle)
  println("")

  match solve(puzzle)
    Nothing -> println("Unsolvable")
    Just(puz) -> println(puz.show-puzzle)
  ()