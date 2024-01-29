extern import
  c { vcpkg = "raylib "}

extern import
  c file "raylib-inline.c"

extern do-some-work() : ()
  c "do_some_work"

pub fun work()
  do-some-work()