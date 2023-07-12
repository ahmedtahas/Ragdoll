extends Sprite2D

@onready var sync: Node2D = get_parent()

func _ready() -> void:
	texture = load("res://assets/sprites/character/equipped/tin/Shockwave.png")
	
	
func _physics_process(_delta: float) -> void:
	if is_multiplayer_authority():
		sync.shockwave_vis = visible
		sync.shockwave_scale = scale.x
	else:
		scale.x = sync.shockwave_scale
		scale.y = sync.shockwave_scale
		visible = sync.shockwave_vis
