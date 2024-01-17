// Sudoku solver & generator

import std/os/file
import std/os/path
import std/os/env
import std/num/random

import sort

// Argument parsing
//==============================================================================

type compileMode
  Solve( puzzlePath : string )
  Generate( num-grids-high : int, num-grids-wide : int, num-cells-to-fill : int )

fun parse-args()
  var generate-usage-msg := "Usage: generate num-grids-high num-grids-wide [num-cells-to-fill]"

  var args := get-args()

  fun parse-cells-to-fill( num-grids-high : int, num-grids-wide : int, args-r : list<string> )
    match args-r
      Nil -> Generate(num-grids-high, num-grids-wide, num-grids-high * num-grids-wide * num-grids-high * num-grids-wide )
      Cons(str, Nil) -> Generate(num-grids-high, num-grids-wide, str.parse-int.unjust)
      _ -> throw(generate-usage-msg)

  fun parse-grids-wide( num-grids-high : int, args-r : list<string> )
    match args-r
      Cons(str, rest) -> parse-cells-to-fill( num-grids-high, str.parse-int.unjust, rest )

  fun parse-grids-high( args-r )
    match args-r
      Cons(str, rest) -> parse-grids-wide( str.parse-int.unjust, rest )
      _ -> throw(generate-usage-msg)

  fun parse-solve-path( args-r )
    match args-r
      Cons(str, Nil) -> Solve(str)
      _ -> throw("Usage: solve puzzle-path")

  match args
    Cons("generate", rest) -> parse-grids-high(rest)
    Cons("solve", rest) -> parse-solve-path(rest)
    _ -> throw("Usage: [solve/generate] [args]")

// Puzzle functions
//==============================================================================

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

fun show-cell( c : cell, cell-width : int ) : string
  match c
    Empty -> " " ++ " ".repeat( cell-width ) ++ " |"
    Number(num) -> 
      var pad-width := cell-width - num.show.count
      " " ++ num.show ++ " ".repeat( pad-width ) ++ " |"

fun show-cells( num-grid-cells : int, row-width : int, c : list<cell>, i : int )
  val max-cell-width = num-grid-cells.show.count

  if i >= c.length then ()
  else
    match c[i]
      Just(cell) ->
        print(cell.show-cell( max-cell-width ))
        if (i + 1) %  row-width == 0 then
          println("")
        else
          print("")
        show-cells( num-grid-cells, row-width, c, i + 1 )

fun show-puzzle( p : puzzle )
  println(p.num-grids-high.show ++ " " ++ p.num-grids-wide.show)
  show-cells(p.num-grid-cells, p.num-grids-high * p.num-grids-wide, p.cells, 0)

fun delete-random-cells(p : puzzle, num-to-delete : int )
  if num-to-delete == 0 then p
  else
    val delete-idx = int(random-float64() * float64(p.num-cells - 1))
    match p.cells[delete-idx]
      Just(cell) ->
        match cell
          Empty -> delete-random-cells(p, num-to-delete)
          Number(_) ->
            delete-random-cells(
              Puzzle(
                p.num-grids-high, p.num-grids-wide,
                p.cells.take(delete-idx) ++ [Empty] ++ p.cells.drop(delete-idx + 1)
              ),
              num-to-delete - 1
            )

// Puzzle TXT file parsing
//==============================================================================

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

// List utility methods
//==============================================================================

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

// Generate a list of random numbers from 1 to n (inclusive)
fun random-number-list( n : int )
  fun swap(l : list<int>, idx1 : int, idx2 : int, i : int, acc : list<int> )
    if i >= l.length then acc
    else if i == idx1 then
      val new-acc = l[idx2].unjust
      swap(l, idx1, idx2, i + 1, acc ++ [new-acc])
    else if i == idx2 then
      val new-acc = l[idx1].unjust
      swap(l, idx1, idx2, i + 1, acc ++ [new-acc])
    else
      val new-acc = l[i].unjust
      swap(l, idx1, idx2, i + 1, acc ++ [new-acc])

  fun shuffle(l : list<int>, num-shufs : int )
    if num-shufs == 0 then l
    else
      val shf-idx1 = int(random-float64() * float64(n - 1))
      val shf-idx2 = int(random-float64() * float64(n - 1))
      val swapped = swap(l, shf-idx1, shf-idx2, 0, [])
      shuffle(swapped, num-shufs - 1)

  shuffle(list(1, n), n * 2)

// Puzzle solving 
//==============================================================================

fun is-legal-all( p : puzzle )
  fun is-legal-all-r( idx )
    if idx >= p.num-cells then True
    else
      all-unique(collect-col(p, idx)) && all-unique(collect-row(p, idx)) && all-unique(collect-grid(p, idx)) && is-legal-all-r(idx + 1)
  
  is-legal-all-r( 0 )

fun solve-idx( p : puzzle, idx : int, num-func )
  if !is-legal-all(p) then Nothing
  else if idx >= p.num-cells then Just( p )
  else
    match p.cells[idx].unjust
      Number(_) -> solve-idx( p, idx + 1, num-func )
      Empty -> solve-cell( p, idx, num-func(), num-func )

fun solve-cell( p : puzzle, cell-idx : int, numbers : list<int>, num-func )
  match numbers
    Nil -> Nothing
    Cons(x, xs) ->
      val puz-with-num = Puzzle(p.num-grids-high, p.num-grids-wide, p.cells.take(cell-idx) ++ [Number(x)] ++ p.cells.drop(cell-idx + 1))
      match solve-idx( puz-with-num, cell-idx + 1, num-func )
        Nothing -> solve-cell( p, cell-idx, xs, num-func )
        Just( puz ) -> Just( puz )

fun solve-puzzle( puzzle-path : string )
  var txt := read-text-file(puzzle-path.path)
  var puzzle := parse(txt)
  println(puzzle.show-puzzle)
  println("")

  match solve-idx( puzzle, 0, fn() { list( 1, puzzle.num-grid-cells ) } )
    Nothing -> println("Unsolvable")
    Just(puz) -> println(puz.show-puzzle)

fun generate-puzzle( grids-high, grids-wide, num-cells-to-fill )
  val empty-puzzle = Puzzle(grids-high, grids-wide, list(1, grids-high * grids-wide * grids-wide * grids-high).map(fn(_) {Empty}))
  val random-solved = solve-idx( empty-puzzle, 0, fn() { random-number-list( empty-puzzle.num-grid-cells ) } ).unjust

  val num-cells-to-delete = random-solved.num-cells - num-cells-to-fill
  val puzzle-with-deleted = delete-random-cells( random-solved, num-cells-to-delete )

  println(puzzle-with-deleted.show-puzzle)

// main
//==============================================================================

fun main()
  var compile-mode := parse-args()

  match compile-mode
    Solve(puzzle-path) -> solve-puzzle(puzzle-path)
    Generate(num-grids-high, num-grids-wide, num-cells-to-fill) -> generate-puzzle(num-grids-high, num-grids-wide, num-cells-to-fill)