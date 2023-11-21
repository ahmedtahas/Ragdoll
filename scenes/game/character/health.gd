extends CanvasLayer

@onready var damage_count: int = 0
@onready var damage_timeout: bool = true
@onready var max_health: float = 0
@onready var current_health: float = 0
@onready var bot_max_health: float = 0
@onready var bot_current_health: float = 0

@onready var character: Node2D = get_node("../../Character")
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_text: Label = $HealthBar/Text
@onready var remote_health_bar: TextureProgressBar = $RemoteHealthBar

signal died
signal bot_died


func _ready() -> void:
	if Global.mode == "single":
		Global.damaged.connect(damage_bot)
	if not is_multiplayer_authority():
		Global.damaged.connect(take_damage)


func set_health(health: float) -> void:
	max_health = health
	current_health = health
	if is_multiplayer_authority():
		health_bar.set_value(100)
		health_text.set_text(str(current_health).pad_decimals(0))
		if Global.mode == "multi":
			remote_health_bar.hide()
		else:
			bot_max_health = Config.get_value("health", "bot")
			bot_current_health = bot_max_health
			remote_health_bar.set_value(100)
	else:
		remote_health_bar.set_value(100)
		health_bar.hide()
		health_text.hide()


@rpc("reliable", "any_peer", "call_remote")
func take_damage(amount: float) -> void:
	if not is_multiplayer_authority():
		take_damage.rpc(amount)
		return
	if not damage_timeout and damage_count > 2:
		character.reset_local()
		Global.reset_positions.emit()
		return
	if amount > 0:
		damage_count += 1
		damage_timeout = false
		damage_timer()
	if current_health <= amount:
		current_health = 0
		update_remote_health.rpc(current_health)
		health_bar.set_value(current_health)
		health_text.set_text(str(current_health).pad_decimals(0))
		Global.player_died.emit()
		return
	current_health -= amount
	if current_health > max_health:
		current_health = max_health
	update_remote_health.rpc(current_health)
	health_bar.set_value((100 * current_health) / max_health)
	health_text.set_text(str(current_health).pad_decimals(0))


func damage_timer() -> void:
	await get_tree().create_timer(0.05).timeout
	damage_timeout = true
	damage_count = 0


@rpc("reliable")
func update_remote_health(current: float) -> void:
	if current == 0:
		Global.opponent_died.emit()
		Global.damaged.disconnect(take_damage)
	remote_health_bar.set_value((100 * current) / max_health)


func damage_bot(amount: float) -> void:
	if bot_current_health <=amount:
		bot_current_health = 0
		remote_health_bar.set_value(bot_current_health)
		Global.opponent_died.emit()
		return
	bot_current_health -= amount
	remote_health_bar.set_value((100 * bot_current_health) / bot_max_health)
