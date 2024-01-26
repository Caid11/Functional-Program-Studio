// Profiling utilities

import std/os/process
import std/time/duration
import std/time/timer

// Below are some utilities to generate Chrome event format traces.
//
// Format details:
// https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU

// Usage: Wrap interesting regions of the code in the "profile" function. This
// will generate prof-evt effects, which can be written to a JSON file and
// viewed in Chrome's trace viewer (open address chrome://tracing in Google Chrome)
//
// Example:
// fun my-cool-func()
//   do-some-work()
//
// var prof-state := create-prof-state( "profile.json ")
//
// fun main()
//   with handler
//     ctl prof-evt( evt ) prof-state := prof-state.handle-evt( evt )
//
//   profile( "my-cool-func", my-cool-func() )
//
//   p.close()

// NOTE: Using this drastically slows the program down (by about 1000x), but is
// good to get a rough picture or to profile specific regions.

// Set to True to enable profiling. If False, the profile() function is a no-op.
val prof-enabled = False

type phase
  Begin
  End

// Struct describing profiler event.
struct profEvent
  name : string
  phase : phase
  ts : int

fun ticks-microseconds()
  ticks().nano-seconds / 1000

fun get-prof-evt( name : string, p : phase )
  ProfEvent( name, p, ticks-microseconds() )

fun to-json( e : profEvent ) : string
  val phase-str = match e.phase
    Begin -> "B"
    End -> "E"
  return "{ \"name\": \"" ++ e.name ++ "\", \"cat\": \"PERF\", \"ph\": \"" ++ phase-str ++ "\", \"ts\": " ++ e.ts.show ++ ", \"pid\": 0, \"tid\": 0 },"

struct profState
  path : string
  events : list<profEvent>

fun create-prof-state( path : string, e : bool )
  if e then run-system( "echo [ > " ++ path) else 0
  ProfState( path, [] )

fun close( s : profState )
  s.events.foreach(fn( evt ){ 
    run-system( "echo " ++ evt.to-json() ++ " >> " ++ s.path )
    ()
  })

val max-evts = 512

fun handle-evt( s : profState, e : profEvent )
  if !prof-enabled then s
  else
    if s.events.length() > max-evts then
      s.events.foreach(fn( evt ){ 
        run-system( "echo " ++ evt.to-json() ++ " >> " ++ s.path )
        ()
      })
      ProfState( s.path, [] )
    else
      ProfState( s.path, s.events ++ [e] )

effect prof-evt
  ctl prof-evt( e : profEvent ) : ()

val profile = 
  if prof-enabled then
    fn( name : string, func )
      prof-evt( get-prof-evt( name, Begin ) )
      val res = func()
      prof-evt( get-prof-evt( name, End ) )
      res
  else
    fn( name : string, func )
      func()