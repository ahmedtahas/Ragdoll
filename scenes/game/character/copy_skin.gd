extends Node2D

@onready var sync: Node2D = get_node("../Extra")

@onready var head: CharacterBody2D = $Head

@onready var body: CharacterBody2D = $Body

@onready var rua: CharacterBody2D = $RUA
@onready var rla: CharacterBody2D = $RLA
@onready var rf: CharacterBody2D = $RF

@onready var lua: CharacterBody2D = $LUA
@onready var lla: CharacterBody2D = $LLA
@onready var lf: CharacterBody2D = $LF

@onready var stomach: CharacterBody2D = $Stomach

@onready var hip: CharacterBody2D = $Hip

@onready var rul: CharacterBody2D = $RUL
@onready var rll: CharacterBody2D = $RLL
@onready var rk: CharacterBody2D = $RK

@onready var lul: CharacterBody2D = $LUL
@onready var lll: CharacterBody2D = $LLL
@onready var lk: CharacterBody2D = $LK


func copy() -> void:
	for child in get_children():
		if get_node("../LocalCharacter/" + str(child.name)).has_node("Sprite"):
			child.get_node("Sprite").texture = get_node("../LocalCharacter/" + str(child.name) + "/Sprite").texture


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		head.global_position = sync.head_pos
		head.global_rotation = sync.head_rot

		body.global_position = sync.body_pos
		body.global_rotation = sync.body_rot

		rua.global_position = sync.rua_pos
		rua.global_rotation = sync.rua_rot
		rla.global_position = sync.rla_pos
		rla.global_rotation = sync.rla_rot
		rf.global_position = sync.rf_pos
		rf.global_rotation = sync.rf_rot

		lua.global_position = sync.lua_pos
		lua.global_rotation = sync.lua_rot
		lla.global_position = sync.lla_pos
		lla.global_rotation = sync.lla_rot
		lf.global_position = sync.lf_pos
		lf.global_rotation = sync.lf_rot

		stomach.global_position = sync.stomach_pos
		stomach.global_rotation = sync.stomach_rot

		hip.global_position = sync.hip_pos
		hip.global_rotation = sync.hip_rot

		rul.global_position = sync.rul_pos
		rul.global_rotation = sync.rul_rot
		rll.global_position = sync.rll_pos
		rll.global_rotation = sync.rll_rot
		rk.global_position = sync.rk_pos
		rk.global_rotation = sync.rk_rot

		lul.global_position = sync.lul_pos
		lul.global_rotation = sync.lul_rot
		lll.global_position = sync.lll_pos
		lll.global_rotation = sync.lll_rot
		lk.global_position = sync.lk_pos
		lk.global_rotation = sync.lk_rot
