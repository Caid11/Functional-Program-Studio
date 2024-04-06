module kincaid-utils

import std/num/ddouble
import std/time/duration
import std/time/timer

extern import
  c file "kincaid-utils-inline.c"

extern kincaid-utils-ks-string(v : vector<char>) : string
  c  "kk_ks_string_from_chars"

pub fun ks-string(v : vector<char>) : string
  kincaid-utils-ks-string(v)

fun sleep-impl(dt : duration, start : duration)
  val elapsed = ticks() - start
  if elapsed > dt then ()
  else
    sleep-impl(dt, start)

pub fun sleep(dt : float64)
  sleep-impl(dt.duration, ticks())