module camera

import std/num/float64

import lmath
import raylib/raylib

pub struct camera
  position : vector3
  pitch : float64
  yaw : float64

pub struct cameraMovement
  mouse-delta : vector2
  move-forward : bool
  move-back : bool
  move-left : bool
  move-right : bool
  move-up : bool
  move-down : bool

val camera-move-rate : float64 = 0.1

pub fun update(c : camera, m : cameraMovement) : camera
  c.update-look(m.mouse-delta)
   .move-forward(m.move-forward)
   .move-back(m.move-back)
   .move-left(m.move-left)
   .move-right(m.move-right)
   .move-up(m.move-up)
   .move-down(m.move-down)

fun move-forward(c : camera, do-move : bool) : camera
  if !do-move then c
  else
    val theta = c.yaw + pi / 2.0
    val forward-vec = camera-move-rate * Vector2(cos(theta),sin(theta))

    val old-pos = c.position
    val new-x = old-pos.x + forward-vec.x
    val new-z = old-pos.z - forward-vec.y
    val new-pos = old-pos(x = new-x, z = new-z)
    c(position = new-pos)

fun move-back(c : camera, do-move : bool) : camera
  if !do-move then c
  else
    val theta = c.yaw - pi / 2.0
    val back-vec = camera-move-rate * Vector2(cos(theta),sin(theta))

    val old-pos = c.position
    val new-x = old-pos.x + back-vec.x
    val new-z = old-pos.z - back-vec.y
    val new-pos = old-pos(x = new-x, z = new-z)
    c(position = new-pos)

fun move-left(c : camera, do-move : bool) : camera
  if !do-move then c
  else
    val theta = c.yaw
    val back-vec = camera-move-rate * Vector2(cos(theta),sin(theta))

    val old-pos = c.position
    val new-x = old-pos.x + back-vec.x
    val new-z = old-pos.z - back-vec.y
    val new-pos = old-pos(x = new-x, z = new-z)
    c(position = new-pos)

fun move-right(c : camera, do-move : bool) : camera
  if !do-move then c
  else
    val theta = c.yaw + pi
    val back-vec = camera-move-rate * Vector2(cos(theta),sin(theta))

    val old-pos = c.position
    val new-x = old-pos.x + back-vec.x
    val new-z = old-pos.z - back-vec.y
    val new-pos = old-pos(x = new-x, z = new-z)
    c(position = new-pos)

fun move-up(c : camera, do-move : bool) : camera
  if !do-move then c
  else
    val up-vec = camera-move-rate * Vector3(0.0, 1.0, 0.0)
    c(position = c.position + up-vec)

fun move-down(c : camera, do-move : bool) : camera
  if !do-move then c
  else
    val up-vec = camera-move-rate * Vector3(0.0, -1.0, 0.0)
    c(position = c.position + up-vec)

fun clamp(v : float64, lo : float64, hi : float64) : float64
  if v < lo then lo
  else if v > hi then hi
  else v

fun wrap(v : float64, lo : float64, hi : float64) : float64
  if v > hi then lo + v % hi
  else if v < lo then hi + v % lo
  else v

fun update-look(c : camera, mouse-delta : vector2) : camera
  val scaled-delta : vector2 = 0.001 * Vector2(-1.0 * mouse-delta.x, -1.0 * mouse-delta.y)

  val max-pitch = 2.0 * pi / 3.0
  val min-pitch = -1.0 * max-pitch
  val new-pitch = clamp(c.pitch + scaled-delta.y, min-pitch, max-pitch)

  val new-yaw = wrap(c.yaw + scaled-delta.x, -1.0 * pi, pi)

  c(pitch = new-pitch, yaw = new-yaw)

pub fun raylib-camera3D(c : camera) : camera3D
  val position = c.position
  val target : vector3 = get-target(position, c.pitch, c.yaw)
  val up = raylib/Vector3(0.0, 1.0, 0.0)
  val fov = 45.0
  val projection = cameraPerspective
  Camera3D(position, target, up, fov, projection)