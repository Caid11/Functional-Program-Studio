module camera

import std/num/float64

import lmath
import raylib/raylib

pub struct camera
  position : vector3
  pitch : float64
  yaw : float64

val camera-move-rate : float64 = 0.1

pub fun move-forward(c : camera) : camera
  val old-pos = c.position
  val new-z = old-pos.z + camera-move-rate
  val new-pos = old-pos(z = new-z)

  c(position = new-pos)

pub fun raylib-camera3D(c : camera) : camera3D
  val position = c.position
  val target = Vector3(0.0, 0.0, 0.0)
  val up = Vector3(0.0, 1.0, 0.0)
  val fov = 45.0
  val projection = cameraPerspective
  Camera3D(position, target, up, fov, projection)