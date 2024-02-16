import std/os/path

import json

fun expect-eq( name : string, parse-cls : () -> <pure,jsonParseFail> jsonValue, expected : jsonValue )
  with handler
    ctl fail( msg : string )
      println("[FAILED] " ++ name )
      println("    Actual: (ERROR) " ++ msg )
      println("    Expected: " ++ expected.show )

  val result = parse-cls()

  if result != expected then
    println("[FAILED] " ++ name )
    println("    Actual: " ++ result.show )
    println("    Expected: " ++ expected.show )
  else
    println("[SUCCEEDED] " ++ name )

fun expect-err( name : string, parse-cls : () -> <pure,jsonParseFail> jsonValue, expected : string )
  with handler
    ctl fail( msg : string )
      if msg == expected then
        println("[SUCCEEDED] " ++ name )
      else
        println("[FAILED] " ++ name )
        println("    Actual: (ERROR) " ++ msg )
        println("    Expected: " ++ expected.show )


  val result = parse-cls()
  println("[FAILED] " ++ name )
  println("    Actual: " ++ result.show )
  println("    Expected: " ++ expected )


fun main()
  expect-eq( "emptyObject",
             { parse-json-string( "{}" ) },
             Object( [] ) )

  expect-eq( "emptyArray",
             { parse-json-string( "[]" ) },
             Array( [] ) )

  expect-eq( "arrayOneNullElement",
             { parse-json-string( "[null]" ) },
             Array( [Null] ) )

  expect-eq( "arrayTwoNullElements",
             { parse-json-string( "[null, null]" ) },
             Array( [Null, Null] ) )

  expect-eq( "arrayOneIntElement",
             { parse-json-string( "[3]" ) },
             Array( [Number( 3.0 )] ) )

  expect-eq( "arrayOneFloatElement",
             { parse-json-string( "[3.2]" ) },
             Array( [Number( 3.2 )] ) )

  expect-err( "arrayOneIntCharElement",
              { parse-json-string( "[3A]" ) },
              "unexpected character when parsing number: A" )

  expect-err( "arrayOneNumTwoDecimalElements",
              { parse-json-string( "[3.3.3]" ) },
              "unexpected character when parsing number: ." )

  expect-eq( "arrayOneTrueElement",
             { parse-json-string( "[true]" ) },
             Array( [Boolean( True )] ) )

  expect-eq( "arrayOneFalseElement",
             { parse-json-string( "[false]" ) },
             Array( [Boolean( False )] ) )

  expect-eq( "arrayOneStringElement",
             { parse-json-string( "[ \"foo bar\" ]" ) },
             Array( [String( "foo bar" )] ) )

  expect-eq( "arrayOneStringEscapedElement",
             { parse-json-string( "[ \"foo \\\" bar\" ]" ) },
             Array( [String( "foo \" bar" )] ) )

  expect-eq( "arrayContainingArray",
             { parse-json-string( "[ [ 5 ] ]" ) },
             Array( [Array( [Number( 5.0 )] )] ) )

  expect-eq( "arrayContainingArrayContainingObject",
             { parse-json-string( "[ [ {\"foo\" : \"bar\" } ] ]" ) },
             Array( [Array( [Object( [JsonPair("foo", String( "bar" ))])] )] ) )

  expect-eq( "objectOneNullField",
             { parse-json-string( "{\"foo\": null}" ) },
             Object( [JsonPair( "foo", Null )] ) )

  expect-eq( "objectTwoFields",
             { parse-json-string( "{\"foo\": null, \"bar\": 5}" ) },
             Object( [JsonPair( "foo", Null ), JsonPair( "bar", Number( 5.0 ))] ) )

  expect-eq( "objectContainingObject",
             { parse-json-string( "{\"foo\": {\"bar\": 5 } }" ) },
             Object( [JsonPair( "foo", Object( [JsonPair( "bar", Number( 5.0 ))]))]))

  expect-eq( "objectContainingArray",
             { parse-json-string( "{\"foo\": [5] }" ) },
             Object( [JsonPair( "foo", Array( [Number( 5.0 )]))]))

  expect-eq( "gameObject",
             { parse-json-string( "{\"day\":1,\"phase\":{\"name\":\"investing\"},\"player\":0,\"players\":[{\"buys\":1,\"cards\":[{\"name\":\"Sorcerer's Stipend\",\"uses\":0}],\"coins\":2},{\"buys\":1,\"cards\":[{\"name\":\"Sorcerer's Stipend\",\"uses\":0}],\"coins\":2}],\"shop\":{\"Board of Monopoly\":4,\"Bubble\":2,\"Ghost\":4,\"Gold Fish\":2,\"Incantation\":6,\"Magic Bean Stock\":2,\"Senior Worker\":4,\"Worker\":4}}" )},
             Object( [
                JsonPair( "day", Number( 1.0 )),
                JsonPair( "phase",
                  Object( [
                    JsonPair( "name", String( "investing" ))
                  ])),
                JsonPair( "player", Number( 0.0 ) ),
                JsonPair( "players", Array( [
                  Object( [
                    JsonPair( "buys", Number( 1.0 )),
                    JsonPair( "cards", Array( [
                      Object( [
                        JsonPair( "name", String( "Sorcerer's Stipend") ),
                        JsonPair( "uses", Number( 0.0 ))
                      ])
                    ])),
                    JsonPair( "coins", Number( 2.0 ))
                  ]),
                  Object( [
                    JsonPair( "buys", Number( 1.0 )),
                    JsonPair( "cards", Array( [
                      Object( [
                        JsonPair( "name", String( "Sorcerer's Stipend") ),
                        JsonPair( "uses", Number( 0.0 ))
                      ])
                    ])),
                    JsonPair( "coins", Number( 2.0 ))
                  ])
                ])),
                JsonPair( "shop", Object([
                  JsonPair( "Board of Monopoly", Number( 4.0 )),
                  JsonPair( "Bubble", Number( 2.0 )),
                  JsonPair( "Ghost", Number( 4.0 )),
                  JsonPair( "Gold Fish", Number( 2.0 )),
                  JsonPair( "Incantation", Number( 6.0 )),
                  JsonPair( "Magic Bean Stock", Number( 2.0 )),
                  JsonPair( "Senior Worker", Number( 4.0 )),
                  JsonPair( "Worker", Number( 4.0 ))
                ]))
             ] ))