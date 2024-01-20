import std/os/file
import std/os/path
import std/os/env
import std/num/random
import std/time/duration
import std/time/timer

// Profiling utilities

struct benchEvent
  name : string
  phase : string
  ts : int

effect bench-evt
  ctl bnch-beg( name : string ) : ()
  ctl bnch-end( name : string ) : ()

// fun bench( name : string, func )
//   bnch-beg( name )
//   val ret = func()
//   bnch-end( name )
//   ret

fun bench( name : string, func )
  func()

fun ticks-microseconds()
  ticks().nano-seconds / 1000

// Argument parsing
//==============================================================================

type compileMode
  Solve( puzzlePath : string )
  Generate( num-grids-high : int, num-grids-wide : int, num-cells-to-fill : int )

effect parse-err
  ctl parse-err( msg : string ) : a

fun parse-args() : <exn,ndet,parse-err> compileMode
  val solve-usage-msg = "Usage: solve puzzle-path"
  val generate-usage-msg = "Usage: generate num-grids-high num-grids-wide [num-cells-to-fill]"

  val args = get-args()

  fun parse-cells-to-fill( num-grids-high : int, num-grids-wide : int, args-r : list<string> )
    match args-r
      Nil -> Generate( num-grids-high, num-grids-wide, num-grids-high * num-grids-wide * num-grids-high * num-grids-wide )
      Cons( str, Nil ) -> Generate( num-grids-high, num-grids-wide, str.parse-int.unjust )
      _ -> parse-err( generate-usage-msg )

  fun parse-grids-wide( num-grids-high : int, args-r : list<string> )
    match args-r
      Cons( str, rest ) -> parse-cells-to-fill( num-grids-high, str.parse-int.unjust, rest )

  fun parse-grids-high( args-r )
    match args-r
      Cons( str, rest ) -> parse-grids-wide( str.parse-int.unjust, rest )
      _ -> parse-err( generate-usage-msg )

  fun parse-solve-path( args-r : list<string> )
    match args-r
      Cons( str, Nil ) -> Solve( str )
      _ -> parse-err("Usage: solve puzzle-path")

  if args.find( fn( x ) { x == "-h" }).is-just then
    parse-err( solve-usage-msg ++ " OR\n" ++ generate-usage-msg )
  else
    match args
      Cons("generate", rest ) -> parse-grids-high( rest )
      Cons("solve", rest ) -> parse-solve-path( rest )
      _ -> parse-err("Usage: [solve/generate] [args]")

// Puzzle functions
//==============================================================================

ref type cell
  Empty
  Number( n : int )

struct puzzle
  num-grids-high : int
  num-grids-wide : int
  cells : list<cell>

fun grid-width( p : puzzle ) : int
  p.num-grids-high

fun grid-height( p : puzzle ) : int
  p.num-grids-wide

fun row-width( p : puzzle ) : int
  p.num-grids-wide * p.num-grids-high

fun col-height( p : puzzle ) : int
  p.num-grids-high * p.num-grids-wide

fun num-grid-cells( p : puzzle ) : int
  p.num-grids-high * p.num-grids-wide

fun num-cells( p : puzzle ) : int
  p.row-width * p.col-height

fun is-legal( p : puzzle, cell-idx : int, num : int )
  fun is-legal-r( i : int, idx-func )
    if i >= p.num-grid-cells then True
    else
      match p.cells[idx-func( i )].unjust
        Empty -> is-legal-r( i + 1, idx-func) 
        Number( cell ) ->
          if cell == num then False
          else is-legal-r( i + 1, idx-func )

  val grid-row-offset = cell-idx / p.row-width / p.grid-height * p.grid-height
  val grid-col-offset = cell-idx % p.row-width / p.grid-width * p.grid-width

  fun grid-idx( i : int )
    val row-offset-in-grid = i / p.grid-width
    val row-offset-in-puz = row-offset-in-grid + grid-row-offset

    val col-offset-in-grid = i % p.grid-width
    val col-offset-in-puz = col-offset-in-grid + grid-col-offset

    row-offset-in-puz * p.row-width + col-offset-in-puz

  val row-low = cell-idx / p.row-width * p.row-width

  fun row-idx( i : int )
    row-low + i

  fun col-idx( i : int )
    val row-offset = p.row-width * i
    row-offset + ( cell-idx % p.row-width )

  is-legal-r( 0, grid-idx ) && is-legal-r( 0, row-idx ) && is-legal-r( 0, col-idx )

pub fun test-is-legal()
  val test-puz = parse( read-text-file( "2x2.txt".path ) )
  println( test-puz.is-legal( 15, 4 ) )

fun show-cell( c : cell, cell-width : int ) : string
  match c
    Empty -> " " ++ " ".repeat( cell-width ) ++ " |"
    Number( num ) -> 
      val pad-width = cell-width - num.show.count
      " " ++ num.show ++ " ".repeat( pad-width ) ++ " |"

fun show-cells( num-grid-cells : int, row-width : int, c : list<cell>, i : int ) : <div,console,exn> ()
  val max-cell-width = num-grid-cells.show.count

  if i >= c.length then ()
  else
    match c[i]
      Just( cell ) ->
        print( cell.show-cell( max-cell-width ))
        if ( i + 1 ) %  row-width == 0 then
          println("")
        else
          print("")
        show-cells( num-grid-cells, row-width, c, i + 1 )

fun show-puzzle( p : puzzle ) : <div,exn,console> ()
  println( p.num-grids-high.show ++ " " ++ p.num-grids-wide.show )
  show-cells( p.num-grid-cells, p.num-grids-high * p.num-grids-wide, p.cells, 0 )

fun delete-random-cells( p : puzzle, num-to-delete : int ) : <div,exn,random> puzzle
  if num-to-delete == 0 then p
  else
    val delete-idx = int( random-float64() * float64( p.num-cells - 1 ))
    match p.cells[delete-idx]
      Just( cell ) ->
        match cell
          Empty -> delete-random-cells( p, num-to-delete )
          Number(_) ->
            delete-random-cells(
              Puzzle(
                p.num-grids-high, p.num-grids-wide,
                p.cells.take( delete-idx ) ++ [Empty] ++ p.cells.drop( delete-idx + 1 )
              ),
              num-to-delete - 1
            )

// Puzzle TXT file parsing
//==============================================================================

fun parse( txt : string ) : <div,exn> puzzle
  fun parse-cells( num-grids-high : int, num-grids-wide : int, txt-slc : sslice, num-str : string, acc : list<cell> )
    match txt-slc.take( 1 ).string
      "" -> Puzzle( num-grids-high, num-grids-wide, acc )
      " " -> parse-cells( num-grids-high, num-grids-wide, txt-slc.advance( 1 ), num-str, acc )
      "\n" -> 
        parse-cells( num-grids-high, num-grids-wide, txt-slc.advance( 1 ), num-str, acc )

      "|" ->
        if num-str.is-empty then parse-cells( num-grids-high, num-grids-wide, txt-slc.advance( 1 ), "", acc ++ [Empty])
        else
          match num-str.parse-int
            Just( num ) -> parse-cells( num-grids-high, num-grids-wide, txt-slc.advance( 1 ), "", acc ++ [Number( num )] )

      str -> parse-cells( num-grids-high, num-grids-wide, txt-slc.advance( 1 ), num-str ++ str, acc )

  fun parse-grids-wide( num-grids-high : int, txt-slc : sslice, num-str : string )
    match txt-slc.take( 1 ).string
      "" -> throw("Unexpected EOF when parsing grid width")
      "\n" ->
        match num-str.parse-int
          Just( num ) -> parse-cells( num-grids-high, num, txt-slc.advance( 1 ), "", [])
      str -> parse-grids-wide( num-grids-high, txt-slc.advance( 1 ), num-str ++ str )

  fun parse-grids-high( txt-slc : sslice, num-str : string )
    match txt-slc.take( 1 ).string
      "" -> throw("Unexpected EOF when parsing grid height")
      " " ->
        match num-str.parse-int
          Just( num ) -> parse-grids-wide( num, txt-slc.advance( 1 ), "")
      str -> parse-grids-high( txt-slc.advance( 1 ), num-str ++ str )

  parse-grids-high( txt.slice, "")

// List utility methods
//==============================================================================

fun drop-idx( l : list<a>, idx : int ) : list<a>
  l.take( idx ) ++ l.drop( idx + 1 )

// Generate a list of random numbers from 1 to n ( inclusive )
fun random-number-list( n : int ) : <div, exn, random> list<int>
  fun swap( l : list<int>, idx1 : int, idx2 : int, i : int, acc : list<int> )
    if i >= l.length then acc
    else if i == idx1 then
      val new-acc = l[idx2].unjust
      swap( l, idx1, idx2, i + 1, acc ++ [new-acc])
    else if i == idx2 then
      val new-acc = l[idx1].unjust
      swap( l, idx1, idx2, i + 1, acc ++ [new-acc])
    else
      val new-acc = l[i].unjust
      swap( l, idx1, idx2, i + 1, acc ++ [new-acc])

  fun shuffle( l : list<int>, num-shufs : int )
    if num-shufs == 0 then l
    else
      val shf-idx1 = int( random-float64() * float64( n - 1 ))
      val shf-idx2 = int( random-float64() * float64( n - 1 ))
      val swapped = swap( l, shf-idx1, shf-idx2, 0, [])
      shuffle( swapped, num-shufs - 1 )

  shuffle( list( 1, n ), n * 2 )

// Puzzle solving 
//==============================================================================

effect select<a>
  ctl select( choices : list<int> ) : a

fun solve-idx( p : puzzle, idx : int ) // : <div,exn,local<_h>,select<(int, list<int>)>> maybe<puzzle>
  if idx >= p.num-cells then Just( p )
  else
    match p.cells[idx].unjust
      Number(_) -> bench( "solve-idx", { solve-idx( p, idx + 1 ) } )
      Empty -> bench( "solve-cell", { solve-cell( p, idx, list( 1, p.num-grid-cells ) ) } )

fun solve-cell( p : puzzle, cell-idx : int, possiblities : list<int> ) // : <div,exn,select<(int, list<int>)>,local<_h>> maybe<puzzle>
  match possiblities
    Nil -> Nothing
    _ ->
      val (next-try, rest) = select( possiblities )
      if p.is-legal( cell-idx, next-try ) then
        val puz-with-num = Puzzle( p.num-grids-high, p.num-grids-wide, p.cells.take( cell-idx ) ++ [Number( next-try )] ++ p.cells.drop( cell-idx + 1 ))
        match bench( "solve-idx", { solve-idx( puz-with-num, cell-idx + 1 ) } )
          Nothing -> bench( "solve-cell", { solve-cell( p, cell-idx, rest ) } )
          Just( puz ) -> Just( puz )
      else
        bench( "solve-cell", { solve-cell( p, cell-idx, rest ) } )

fun solve-puzzle( puzzle-path : string ) // : <console,div,exn,fsys> ()
  val txt = read-text-file( puzzle-path.path )
  val puzzle = parse( txt )
  println( puzzle.show-puzzle )
  println("")

  with ctl select( choices )
    match choices
      Cons( x, xs ) -> resume( (x, xs) )

  match bench( "solve-idx", { solve-idx( puzzle, 0 ) } )
    Nothing -> println("Unsolvable")
    Just( puz ) -> println( puz.show-puzzle )

fun generate-puzzle( grids-high, grids-wide, num-cells-to-fill ) // : <console,div,exn,random> ()
  val empty-puzzle = Puzzle( grids-high, grids-wide, list( 1, grids-high * grids-wide * grids-wide * grids-high ).map( fn(_) {Empty}))

  with ctl select( choices : list<int> )
      val idx = int( random-float64() * float64( choices.length - 1 ))
      resume(( choices.list/index(idx).unjust, choices.drop-idx( idx ) ))

  val random-solved = solve-idx( empty-puzzle, 0 ).unjust

  val num-cells-to-delete = random-solved.num-cells - num-cells-to-fill
  val puzzle-with-deleted = delete-random-cells( random-solved, num-cells-to-delete )

  println( puzzle-with-deleted.show-puzzle )

// main
//==============================================================================

fun main() : <console,div,exn,fsys,ndet,random> ()
  with handler
    ctl parse-err( msg ) println( msg )

  // var bnch-evts := Nil
  // with handler
  //   ctl bnch-beg( name )
  //     bnch-evts := Cons( BenchEvent( name, "B", ticks-microseconds() ), bnch-evts )
  //     resume( () )
  //   ctl bnch-end( name )
  //     bnch-evts := Cons( BenchEvent( name, "E", ticks-microseconds() ), bnch-evts )
  //     resume( () )

  val compile-mode = parse-args()

  match compile-mode
    Solve( puzzle-path ) -> print-elapsed{ bench( "solve-puzzle", { solve-puzzle( puzzle-path ) } ) }
    Generate( num-grids-high, num-grids-wide, num-cells-to-fill ) -> print-elapsed{ generate-puzzle( num-grids-high, num-grids-wide, num-cells-to-fill ) }

  // fun bnch-evts-to-string( curr )
  //   match curr
  //     Nil -> ""
  //     Cons( x, xs ) -> 
  //       match x
  //         BenchEvent( name, ph, ts ) ->
  //           bnch-evts-to-string( xs ) ++ ",\n{ \"name\": \"" ++ name ++ "\", \"cat\": \"PERF\", \"ph\": \"" ++ ph ++ "\", \"ts\": " ++ ts.show ++ ", \"pid\": 0, \"tid\": 0 }"
  
  // ()
  // write-text-file( "profile.json".path, "[\n" ++ bnch-evts-to-string( bnch-evts ) )
