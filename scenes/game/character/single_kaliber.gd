extends Node2D

@onready var character_name: String = "kaliber"

@onready var duration_time: float
@onready var max_combo: float
@onready var damage: float

@onready var cooldown_bar: TextureProgressBar
@onready var cooldown_text: RichTextLabel

@onready var radius: Vector2 = $Extra/Center/Reach.position
@onready var center: Vector2 = $Extra/Center.position

@onready var character: Node2D = $Extra/Character
@onready var joy_stick: CanvasLayer = $Extra/DoubleJoyStick
@onready var body: RigidBody2D = $LocalCharacter/Body
@onready var cooldown: Timer = $Extra/SkillCooldown
@onready var duration: Timer = $Extra/SkillDuration

@onready var using: bool = false
@onready var hit_count: float = 0


func _ready() -> void:
	name = character_name
	
	get_node("LocalCharacter").load_skin(character_name)
	
	_ignore_self()
	
	joy_stick.move_signal.connect(character.move_signal)
	joy_stick.skill_signal.connect(self.skill_signal)
	joy_stick.button = true
	character.hit_signal.connect(self.hit_signal)
	
	max_combo = get_node("/root/Config").get_value("duration", character_name)
	duration_time = get_node("/root/Config").get_value("cooldown", character_name)
	damage = get_node("/root/Config").get_value("damage", character_name)
	
	duration.wait_time = duration_time

	cooldown_bar = character.get_node('LocalUI/CooldownBar')
	cooldown_text = character.get_node('LocalUI/CooldownBar/Text')

	cooldown_bar.set_value(100)
	cooldown_text.set_text("[center]ready[/center]")	
			
	for part in get_node("LocalCharacter").get_children():
		part.set_power(character_name)
	

func _physics_process(_delta: float) -> void:
	if not duration.is_stopped():
		cooldown_bar.set_value((100 * duration.time_left) / duration_time)
		cooldown_text.set_text("[center]" + str(duration.time_left).pad_decimals(1) + "s[/center]")
	
	else:
		cooldown_bar.set_value((100 * hit_count) / max_combo)
		cooldown_text.set_text("[center]" + str(hit_count) + "x[/center]")
	
	
func _ignore_self() -> void:
	for child_1 in get_node("LocalCharacter").get_children():
		child_1.body_entered.connect(character.on_body_entered.bind(child_1))
		for child_2 in get_node("LocalCharacter").get_children():
			if child_1 != child_2:
				child_1.add_collision_exception_with(child_2)


func hit_signal() -> void:
	if using or hit_count == max_combo:
		return
	hit_count += 1


func skill_signal(_using: bool) -> void:
	if not duration.is_stopped() or hit_count <= 2:
		return
	
	if _using:
		pass
	
	else:
		Global.world.slow_motion(0.05, 1)
		character.damage *= (hit_count / 2)
		duration.wait_time = duration_time * hit_count / max_combo
		duration.start()
		await duration.timeout
		character.damage = damage
		hit_count = 0
