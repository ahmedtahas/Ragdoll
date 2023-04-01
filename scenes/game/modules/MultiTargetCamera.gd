extends Camera2D

var camera_speed =0.5 # camera position lerp speed
var zoom_speed = 0.25  
var min_zoom = 0.25  
var max_zoom = 15  
var margin = Vector2(1200, 800) 

var targets = [] 
var position_vectors: Vector2
var rect: Rect2
var zoom_amount: float

@onready var screen_size = get_viewport_rect().size


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
	


func add_target(target):
	if not target in targets:
		targets.append(target)

func remove_target(target):
	if target in targets:
		targets.erase(target)
