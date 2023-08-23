extends Node2D



@export var Head: Vector3 = Vector3.ZERO
@export var Body: Vector3 = Vector3.ZERO
@export var RUA: Vector3 = Vector3.ZERO
@export var RLA: Vector3 = Vector3.ZERO
@export var RF: Vector3 = Vector3.ZERO
@export var LUA: Vector3 = Vector3.ZERO
@export var LLA: Vector3 = Vector3.ZERO
@export var LF: Vector3 = Vector3.ZERO
@export var Stomach: Vector3 = Vector3.ZERO
@export var Hip: Vector3 = Vector3.ZERO
@export var RUL: Vector3 = Vector3.ZERO
@export var RLL: Vector3 = Vector3.ZERO
@export var RK: Vector3 = Vector3.ZERO
@export var LUL: Vector3 = Vector3.ZERO
@export var LLL: Vector3 = Vector3.ZERO
@export var LK: Vector3 = Vector3.ZERO


@export var health: float = 0

@export var aim: Vector2 = Vector2.ZERO

@export var shockwave_vis: bool = false
@export var shockwave_scale: float = 0

@export var shield_scale: float = 0

@export var particles_emitting: bool = false
