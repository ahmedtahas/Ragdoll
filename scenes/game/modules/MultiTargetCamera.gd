extends Camera2D

@onready var camera_speed: float = 0.5
@onready var zoom_speed: float = 0.25
@onready var min_zoom: float = 0.25
@onready var max_zoom: float = 15
@onready var margin: Vector2 = Vector2(1200, 800)

@onready var targets = []
@onready var position_vectors: Vector2
@onready var rect: Rect2
@onready var zoom_amount: float
@onready var black_screen: ColorRect = $BlackScreen

@onready var screen_size = get_viewport_rect().size


func _ready() -> void:
	Global.black_out.connect(self.black_out)

func _physics_process(_delta: float) -> void:
	if targets.size() < 1:
		return
	position_vectors = Vector2.ZERO
	for target in targets:
		position_vectors += target.global_position
	position_vectors /= targets.size()
	position = lerp(position, position_vectors, camera_speed)

	rect = Rect2(position, Vector2.ONE)
	for target in targets:
		rect = rect.expand(target.global_position)
	rect = rect.grow_individual(margin.x, margin.y, margin.x, margin.y)

	if rect.size.x > rect.size.y * screen_size.aspect():
		zoom_amount = clamp(rect.size.x / screen_size.x, min_zoom, max_zoom)
	else:
		zoom_amount = clamp(rect.size.y / screen_size.y, min_zoom, max_zoom)

	if zoom_amount >= max_zoom:
		zoom_amount = 14.9999999
	elif zoom_amount <= min_zoom:
		zoom_amount = 0.5000001

	zoom = lerp(zoom, Vector2.ONE * (1 / zoom_amount), zoom_speed)


func black_out(duration: float):
	for target in targets:
		if target is CharacterBody2D:
			remove_target(target)
			black_screen.visible = true
			await get_tree().create_timer(duration).timeout
			add_target(target)
			black_screen.visible = false




func add_target(target) -> void:
	if not target in targets:
		targets.append(target)


func remove_target(target) -> void:
	if target in targets:
		targets.erase(target)
