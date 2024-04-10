module lmath

import raylib/raylib

import std/num/float64

pub fun float64-vector2/(*)(i : float64, v : vector2) : vector2
  val new-x = v.x * i
  val new-y = v.y * i
  Vector2(new-x, new-y)

pub fun vector3/(+)(v1 : vector3, v2 : vector3) : vector3
  Vector3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)

pub fun vector3/(-)(v1 : vector3, v2 : vector3) : vector3
  Vector3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)

pub fun float64-vector3/(*)(i : float64, v : vector3) : vector3
  val new-x = v.x * i
  val new-y = v.y * i
  val new-z = v.z * i
  Vector3(new-x, new-y, new-z)

pub fun vector3-float64/(*)(v : vector3, i : float64) : vector3
  float64-vector3/(*)(i, v)

pub fun cross(v1 : vector3, v2 : vector3) : vector3
  val new-x = v1.y * v2.z - v1.z * v2.y
  val new-y = v1.z * v2.x - v1.x * v2.z
  val new-z = v1.x * v2.y - v1.y * v2.x
  Vector3(new-x, new-y, new-z)

pub fun dot(v1 : vector3, v2 : vector3) : float64
  v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

pub fun rotate(x : vector3, axis : vector3, angle : float64)
  // https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
  x * cos(angle) + axis.cross(x) * sin(angle) + axis * (axis.dot(x)) * (1.0 - cos(angle))

pub fun get-target(pos : vector3, pitch : float64, yaw : float64) : vector3
  val unit-forward = Vector3(0.0, 0.0, 1.0)
  val rotated-pitch = unit-forward.rotate( Vector3(1.0, 0.0, 0.0), pitch)
  val rotated-yaw = rotated-pitch.rotate( Vector3(0.0, 1.0, 0.0), yaw)
  val translated = pos - rotated-yaw

  translated