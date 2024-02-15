import std/num/float64
import std/os/path

pub type jsonValue
  Number( num : float64 )
  String( str : string )
  Boolean( b : bool )
  Array( l : list<jsonValue> )
  Object( l : list<jsonPair> )
  Null

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

pub struct jsonPair
  name : string
  value : jsonValue

pub fun jsonPair/(==)( x : jsonPair, y : jsonPair ) : div bool
  x.name == y.name && x.value == y.value

pub fun jsonPair/(!=)( x : jsonPair, y : jsonPair ) : div bool
  !(x == y)

pub fun jsonValue/show( v : jsonValue )
  match v
    Number( num : float64 ) -> num.show
    String( str : string ) -> "\"" ++ str ++ "\""
    Boolean( b : bool ) -> if b then "true" else "false"
    Array( l : list<jsonValue> ) -> "[" ++ l.map( show ).join( ", ") ++ "]"
    Object( l : list<jsonPair> ) -> "{" ++ l.map( show ).join( ", ") ++ "}"
    Null -> "null"

pub fun jsonPair/show( p : jsonPair )
  "\"" ++ p.name ++ "\": " ++ p.value.show

pub fun parse-json-file( p : path ) : <exn,fsys> jsonValue
  Object( [] )