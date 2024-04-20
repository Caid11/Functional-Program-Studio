import tests/test-commands
import tests/test-coroutines
import tests/test-socket
import tests/test-world
import tests/test

val all-cases = [
  socket-tests,
  command-tests,
  coroutine-tests,
  world-tests
]

fun main()
  run-tests(all-cases)