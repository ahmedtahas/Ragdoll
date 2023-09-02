extends Camera2D

@onready var camera_speed: float = 0.5
@onready var zoom_speed: float = 0.25
@onready var min_zoom: float = 0.2
@onready var max_zoom: float = 15
@onready var margin: Vector2 = Vector2(1200, 800)

@onready var targets = []
@onready var position_vectors: Vector2
@onready var rect: Rect2
@onready var zoom_amount: float
@onready var black_screen: ColorRect = $BlackScreen
@onready var game_started: bool = false
@onready var screen_size = get_viewport_rect().size
@onready var blacking_out: bool = false
@onready var objects = []


func _ready() -> void:
	Global.black_out.connect(self.black_out)
	Global.two_players_joined.connect(self.start)

func _physics_process(_delta: float) -> void:
	if targets.size() < 1:
		return
	if not game_started:
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

	zoom = lerp(zoom, Vector2.ONE * (1 / zoom_amount), zoom_speed)


func black_out(duration: float):
	blacking_out = true
	objects = []
	for target in targets:
		if target is CharacterBody2D or (target is Marker2D and target == Global.opponent.center):
			var wr = weakref(target)
			objects.append(wr)
	for target in objects:
		if target.get_ref():
			remove_target(target.get_ref())
	black_screen.visible = true
	await get_tree().create_timer(duration).timeout
	blacking_out = false
	for target in objects:
		if target.get_ref():
			add_target(target.get_ref())
	black_screen.visible = false



func start() -> void:
	game_started = true


func add_target(target) -> void:
	if blacking_out:
		var wr = weakref(target)
		objects.append(wr)
		return
	if not target in targets:
		targets.append(target)


func remove_target(target) -> void:
	if target in targets:
		targets.erase(target)
