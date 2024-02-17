import std/num/float64
import std/os/file
import std/os/path

pub type jsonValue
  Number( num : float64 )
  String( str : string )
  Boolean( b : bool )
  Array( l : list<jsonValue> )
  Object( l : list<jsonPair> )
  Null

pub struct jsonPair
  name : string
  value : jsonValue

effect jsonParseFail
  ctl fail( msg : string ) : a

pub fun jsonValue/(==)( x : jsonValue, y : jsonValue ) : div bool
  match x
    Number( x-num ) ->
      match y
        Number( y-num ) -> x-num == y-num
        _ -> False
    String( x-str ) ->
      match y
        String( y-str ) -> x-str == y-str
        _ -> False
    Boolean( x-b ) ->
      match y
        Boolean( y-b ) -> x-b == y-b
        _ -> False
    Array( x-l ) ->
      match y
        Array( y-l ) -> x-l.zip( y-l ).all( fn( (x-a,y-a) ){ x-a == y-a })
        _ -> False
    Object( x-l ) ->
      match y
        Object( y-l ) ->
          x-l.length == y-l.length && x-l.zip( y-l ).all( fn( (x-o,y-o) ){ x-o == y-o })
        _ -> False
    Null -> y.is-null

pub fun jsonValue/(!=)( x : jsonValue, y : jsonValue ) : div bool
  !(x == y)

pub fun jsonValue/show( v : jsonValue )
  match v
    Number( num : float64 ) -> num.show
    String( str : string ) -> "\"" ++ str ++ "\""
    Boolean( b : bool ) -> if b then "true" else "false"
    Array( l : list<jsonValue> ) -> "[" ++ l.map( show ).join( ", ") ++ "]"
    Object( l : list<jsonPair> ) -> "{" ++ l.map( show ).join( ", ") ++ "}"
    Null -> "null"

pub fun key( v : jsonValue, key-name : string ) : <pure> jsonValue
  match v
    Object( pairs ) ->
      val res = pairs.find( fn(p){ p.name == key-name } )
      match res
        Just( p ) -> p.value

pub fun jsonValue/int( v : jsonValue )
  match v
    Number( n ) -> n.int

pub fun jsonValue/string( v : jsonValue )
  match v
    String( s ) -> s

pub fun jsonValue/array( v : jsonValue )
  match v
    Array( elems ) -> elems

pub fun jsonPair/(==)( x : jsonPair, y : jsonPair ) : div bool
  x.name == y.name && x.value == y.value

pub fun jsonPair/(!=)( x : jsonPair, y : jsonPair ) : div bool
  !(x == y)

pub fun jsonPair/show( p : jsonPair )
  "\"" ++ p.name ++ "\": " ++ p.value.show

pub fun parse-json-file( p : path ) : <pure,fsys,jsonParseFail> jsonValue
  val contents = read-text-file( p )
  parse-json-string( contents )

pub fun parse-json-string( s : string ) : <pure,jsonParseFail> jsonValue
  parse-json( s.list )

// We're parsing either an object or an array. Find first delimiter to indicate
// which.
fun parse-json( s : list<char> )
  match s
    Nil -> fail( "unexpected end of json" )
    Cons( '{', _ ) ->
      val (object, object-rest) = parse-json-object( s )
      if object-rest.consume-whitespace.length > 0 then fail( "expected a single top-level array or object" )
      else object
    Cons( '[', _ ) ->
      val (array, array-rest) = parse-json-array( s )
      if array-rest.consume-whitespace.length > 0 then fail( "expected a single top-level array or object" )
      else array

fun parse-json-object( s : list<char>, pairs : list<jsonPair> = [] )
  match s
    Nil -> fail( "unexpected end of object" )
    Cons( '}', rest ) -> (Object( pairs ), rest)
    Cons( '{', rest ) ->
      match rest.consume-whitespace
        Cons( '}', rest-closed ) -> (Object( pairs ), rest-closed)
        _ ->
          val (name, name-rest) = parse-string( rest.consume-whitespace.drop(1) )
          match name
            String( name-str ) ->
              match name-rest.consume-whitespace
                Nil -> fail("unexpected end of object")
                Cons( ':', rest-colon ) ->
                  val (value, value-rest) = parse-json-value( rest-colon.consume-whitespace )
                  parse-json-object( value-rest.consume-whitespace, pairs ++ [JsonPair(name-str, value)] )
                Cons( c, _ ) -> fail( "unexpected character when parsing object: " ++ c.string)
    Cons( ',', rest ) ->
      val (name, name-rest) = parse-string( rest.consume-whitespace.drop(1) )
      match name
        String( name-str ) ->
          match name-rest.consume-whitespace
            Nil -> fail("unexpected end of object")
            Cons( ':', rest-colon ) ->
              val (value, value-rest) = parse-json-value( rest-colon.consume-whitespace )
              parse-json-object( value-rest.consume-whitespace, pairs ++ [JsonPair(name-str, value)] )
            Cons( c, _ ) -> fail( "unexpected character when parsing object: " ++ c.string)

fun parse-json-array( s : list<char>, elements : list<jsonValue> = [] )
  match s.consume-whitespace
    Nil -> fail( "unexpected end of array" )
    Cons( ']', rest ) -> (Array( elements ), rest)
    Cons( ',', rest ) -> 
      val (json-value, after-value) = parse-json-value( rest.consume-whitespace )
      parse-json-array( after-value, elements ++ [json-value] )
    Cons( '[', rest ) -> 
      match rest.consume-whitespace
        Cons( ']', rest-closed ) -> (Array( elements ), rest-closed)
        _ -> 
          val (json-value, after-value) = parse-json-value( rest.consume-whitespace )
          parse-json-array( after-value, elements ++ [json-value] )
    Cons( c, _ ) -> fail( "unexpected character when parsing array: " ++ c.string )

fun consume-whitespace( s : list<char> )
  match s
    Cons( c, rest ) -> if c.is-white then consume-whitespace( rest ) else s
    Nil -> s

fun int/peek( s : list<char>, num : int )
  (s.take( num ), s.drop( num ))

fun string/peek( s : list<char>, chars : string )
  val (peeked-chars, peeked-rest) = s.peek( chars.count )
  (peeked-chars.string == chars, peeked-rest)

fun parse-json-value( s : list<char> )
  match s
    Cons( 'n', _ ) -> parse-null( s )
    Cons( 't', _ ) -> parse-bool( s )
    Cons( 'f', _ ) -> parse-bool( s )
    Cons( '"', rest ) -> parse-string( rest )
    Cons( '{', _ ) -> parse-json-object( s )
    Cons( '[', _ ) -> parse-json-array( s )
    Cons( c, _ ) ->
      if c.is-digit then parse-number( s )
      else fail( "unrecognized json value character" )

fun parse-null( s : list<char> )
  val (null-chars, rest) = s.peek(4)
  if null-chars.string != "null" then fail( "unexpected char" )
  else (Null, rest)

fun parse-bool( s : list<char> )
  val (has-true, true-rest) = s.peek( "true" )
  val (has-false, false-rest) = s.peek( "false" )

  if has-true then (Boolean( True ), true-rest )
  else if has-false then (Boolean( False ), false-rest )
  else fail( "unexpected chars parsing bool: " ++ s.take(5).string )

fun parse-number( s : list<char>, num-chars : list<char> = [] )
  match s
    Cons( '.', rest ) ->
      if num-chars.find( fn(c){ c == '.' }).is-just then
        fail( "unexpected character when parsing number: .")
      else parse-number( rest, num-chars ++ ['.'] )
    Cons( c, rest ) ->
      if c.is-alpha then fail( "unexpected character when parsing number: " ++ c.string)
      else if c.is-digit then parse-number( rest, num-chars ++ [c] )
      else
        val num-parsed = parse-float64( num-chars.string )
        match num-parsed
          Nothing -> fail( "failed to parse number: " ++ num-chars.string )
          Just( num ) -> (Number( num ), s)

fun parse-string( s : list<char>, str-chars : list<char> = [] )
  match s
    Nil -> fail( "unexpected end of string" )
    Cons( '"', rest ) -> (String( str-chars.string ), rest )
    Cons( '\\', rest ) ->
      match rest
        Cons( c, rest-next ) -> parse-string( rest-next, str-chars ++ [c] )
    Cons( c, rest ) -> parse-string( rest, str-chars ++ [c] )