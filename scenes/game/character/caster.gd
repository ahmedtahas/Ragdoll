extends CharacterBody2D

@onready var sync: Node2D = $"../../Extra"

func _physics_process(_delta: float) -> void:
	match name:
		"Head":
			global_position = Vector2(sync.Head.x, sync.Head.y)
			global_rotation = sync.Head.z
		"Body":
			global_position = Vector2(sync.Body.x, sync.Body.y)
			global_rotation = sync.Body.z
		"RUA":
			global_position = Vector2(sync.RUA.x, sync.RUA.y)
			global_rotation = sync.RUA.z
		"RLA":
			global_position = Vector2(sync.RLA.x, sync.RLA.y)
			global_rotation = sync.RLA.z
		"RF":
			global_position = Vector2(sync.RF.x, sync.RF.y)
			global_rotation = sync.RF.z
		"LUA":
			global_position = Vector2(sync.LUA.x, sync.LUA.y)
			global_rotation = sync.LUA.z
		"LLA":
			global_position = Vector2(sync.LLA.x, sync.LLA.y)
			global_rotation = sync.LLA.z
		"LF":
			global_position = Vector2(sync.LF.x, sync.LF.y)
			global_rotation = sync.LF.z
		"RUL":
			global_position = Vector2(sync.RUL.x, sync.RUL.y)
			global_rotation = sync.RUL.z
		"RLL":
			global_position = Vector2(sync.RLL.x, sync.RLL.y)
			global_rotation = sync.RLL.z
		"LUL":
			global_position = Vector2(sync.LUL.x, sync.LUL.y)
			global_rotation = sync.LUL.z
		"LLL":
			global_position = Vector2(sync.LLL.x, sync.LLL.y)
			global_rotation = sync.LLL.z
		"Stomach":
			global_position = Vector2(sync.Stomach.x, sync.Stomach.y)
			global_rotation = sync.Stomach.z
		"Hip":
			global_position = Vector2(sync.Hip.x, sync.Hip.y)
			global_rotation = sync.Hip.z
		"RK":
			global_position = Vector2(sync.RK.x, sync.RK.y)
			global_rotation = sync.RK.z
		"LK":
			global_position = Vector2(sync.LK.x, sync.LK.y)
			global_rotation = sync.LK.z
