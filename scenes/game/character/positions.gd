extends Node2D


@export var part_dict: Dictionary = {
	"Head": Vector3.ZERO,
	"Body": Vector3.ZERO,
	"RUA": Vector3.ZERO,
	"RLA": Vector3.ZERO,
	"RF": Vector3.ZERO,
	"LUA": Vector3.ZERO,
	"LLA": Vector3.ZERO,
	"LF": Vector3.ZERO,
	"Stomach": Vector3.ZERO,
	"Hip": Vector3.ZERO,
	"RUL": Vector3.ZERO,
	"RLL": Vector3.ZERO,
	"RK": Vector3.ZERO,
	"LUL": Vector3.ZERO,
	"LLL": Vector3.ZERO,
	"LK": Vector3.ZERO
	}


@export var health: float = 0

@export var aim: Vector2 = Vector2.ZERO

@export var shockwave_vis: bool = false
@export var shockwave_scale: float = 0

@export var shield_scale: float = 0

@export var particles_emitting: bool = false


