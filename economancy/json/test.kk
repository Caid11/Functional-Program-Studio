import std/os/path

import json

fun expect-eq( msg : string, result-maybe : maybe<jsonValue>, expected : jsonValue )
  match result-maybe
    Nothing -> 
      println("[FAILED] " ++ msg )
      println("    Actual: (NOTHING)" )
      println("    Expected: " ++ expected.show )
    Just( result ) ->
      if result != expected then
        println("[FAILED] " ++ msg )
        println("    Actual: " ++ result.show )
        println("    Expected: " ++ expected.show )
      else
        println("[SUCCEEDED] " ++ msg )

fun main()
  val empty = parse-json-file("test-cases/empty.json".path)
  expect-eq( "emptyObject", empty, Object( Nil ) )