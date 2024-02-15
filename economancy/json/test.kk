import std/os/path

import json

fun same-ty( x : jsonValue, y )
  False

fun expect-eq( msg : string, result : jsonValue, expected : jsonValue )
  if result != expected then
    println("[FAILED] " ++ msg )
    println("    Actual: " ++ result.show )
    println("    Expected: " ++ expected.show )
  else
    println("[SUCCEEDED] " ++ msg )

fun main()
  val empty = parse-json-file("test-cases/empty.json".path)
  expect-eq( "emptyObject", empty, Object( Nil ) )