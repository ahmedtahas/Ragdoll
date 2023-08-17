extends ResourcePreloader

@export var noise = NoiseTexture2D.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var texture = NoiseTexture2D.new()
	texture.noise = FastNoiseLite.new()
	await texture.changed
	var image = texture.get_image()
	var data = image.get_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
