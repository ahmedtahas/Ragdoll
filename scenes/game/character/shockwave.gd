extends Sprite2D

@onready var sync: Node2D = get_parent()
@onready var is_singleplayer: bool = false

func _ready() -> void:
	texture = load("res://assets/sprites/character/equipped/tin/Shockwave.png")
	if sync.get_parent().get_child_count() == 2:
		is_singleplayer = true


func _physics_process(_delta: float) -> void:
	if is_singleplayer:
		return

	if is_multiplayer_authority():
		sync.shockwave_vis = visible
		sync.shockwave_scale = scale.x
	else:
		scale.x = sync.shockwave_scale
		scale.y = sync.shockwave_scale
		visible = sync.shockwave_vis
