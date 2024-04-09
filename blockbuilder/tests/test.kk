// This module contains functions for constructing and dispatching tests.

module tests/test

import std/num/ddouble
import std/time/duration
import std/time/timer

pub effect test-fail
  ctl test-fail(msg : string) : a

type testResult
  Fail(msg : string)
  Success

pub value struct test
  name: string
  test-fn: () -> <io,test-fail> ()

pub value struct case
  name: string
  tests: list<test>

struct testOutput
  full-name: string
  result: testResult
  ms-elapsed: int

fun dispatch-test-func(test-fn) : _e testResult
  with final ctl test-fail(msg)
    Fail(msg)
  
  test-fn()
  Success

fun run-test(case-name: string, t: test): _e testOutput
  val full-test-name = case-name ++ "." ++ t.name
  println(green("[ RUN      ] ") ++ full-test-name)

  val (test-time, test-result) : (duration, testResult) = elapsed( { dispatch-test-func({ t.test-fn }) })

  val (status-msg, test-msg) = match test-result
    Success -> (green("[       OK ]"), "")
    Fail(msg) -> (red("[  FAILED  ]"), msg)

  if test-msg.count > 0 then
    println(test-msg)
  else ()

  val test-ms: int = test-time.milli-seconds
  println(status-msg ++ " " ++ full-test-name ++ " (" ++ test-ms.show ++ " ms)")

  TestOutput(full-test-name, test-result, test-ms)

fun run-test-case(case: case): _e list<testOutput>
  println(green("[----------] ") ++ case.tests.length.show ++ " tests from " ++ case.name)

  val res = case.tests.map(fn(t) run-test(case.name, t))
  val total-ms = res.map(fn(o) o.ms-elapsed).sum

  println(green("[----------] ") ++ case.tests.length.show ++ " tests from " ++ case.name ++ " (" ++ total-ms.show ++ " ms total)")

  res

pub fun run-tests(cases : list<case>)
  val num-tests = cases.flatmap(fn(c) c.tests).length
  println(green("[==========]") ++ " Running " ++ num-tests.show ++ " tests from " ++ cases.length.show ++ " test cases." )

  val test-outputs = cases.flatmap(fn(c) run-test-case(c))
  val num-passed = test-outputs.filter(fn(o) o.result.is-success).length
  val failed-tests = test-outputs.filter(fn(o) o.result.is-fail)

  val total-ms = test-outputs.map(fn(o) o.ms-elapsed).sum
  println(green("[==========] ") ++ num-tests.show ++" tests from " ++ cases.length.show ++ " test cases ran. (" ++ total-ms.show ++ " ms total)")
  println(green("[  PASSED  ] ") ++ num-passed.show ++ " tests.")

  if failed-tests.length > 0 then
    println(red("[  FAILED  ] ") ++ failed-tests.length.show ++ " tests, listed below:")
    failed-tests.map(fn(o) println(red("[  FAILED  ] ") ++ o.full-name))
    ()
  else ()

pub fun expected-actual-msg(expected: string, actual: string): _e string
  "Expected: " ++ expected ++ "\nActual: " ++ actual

val reset = "\u001b[0m"
fun green(msg : string): string
  "\u001b[32m" ++ msg ++ reset

fun red(msg : string): string
  "\u001b[31m" ++ msg ++ reset
