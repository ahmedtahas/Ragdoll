extends Node2D


@export var head_pos: Vector2 = Vector2.ZERO
@export var body_pos: Vector2 = Vector2.ZERO
@export var rua_pos: Vector2 = Vector2.ZERO
@export var rla_pos: Vector2 = Vector2.ZERO
@export var rf_pos: Vector2 = Vector2.ZERO
@export var lua_pos: Vector2 = Vector2.ZERO
@export var lla_pos: Vector2 = Vector2.ZERO
@export var lf_pos: Vector2 = Vector2.ZERO
@export var stomach_pos: Vector2 = Vector2.ZERO
@export var hip_pos: Vector2 = Vector2.ZERO
@export var rul_pos: Vector2 = Vector2.ZERO
@export var rll_pos: Vector2 = Vector2.ZERO
@export var rk_pos: Vector2 = Vector2.ZERO
@export var lul_pos: Vector2 = Vector2.ZERO
@export var lll_pos: Vector2 = Vector2.ZERO
@export var lk_pos: Vector2 = Vector2.ZERO
@export var head_rot: float = 0
@export var body_rot: float = 0
@export var rua_rot: float = 0
@export var rla_rot: float = 0
@export var rf_rot: float = 0
@export var lua_rot: float = 0
@export var lla_rot: float = 0
@export var lf_rot: float = 0
@export var stomach_rot: float = 0
@export var hip_rot: float = 0
@export var rul_rot: float = 0
@export var rll_rot: float = 0
@export var rk_rot: float = 0
@export var lul_rot: float = 0
@export var lll_rot: float = 0
@export var lk_rot: float = 0


@export var health: float = 0

@export var aim: Vector2 = Vector2.ZERO

@export var shockwave_vis: bool = false
@export var shockwave_scale: float = 0

@export var shield_scale: float = 0

@export var particles_emitting: bool = false
