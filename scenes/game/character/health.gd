extends CanvasLayer

@onready var max_health: float = 0
@onready var current_health: float = 0
@onready var bot_max_health: float = 0
@onready var bot_current_health: float = 0

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var health_text: RichTextLabel = $HealthBar/Text
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
		health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")
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


@rpc("reliable", "any_peer", "call_remote", 1)
func take_damage(amount: float) -> void:
	if not is_multiplayer_authority():
		take_damage.rpc(amount)
		return
	if current_health <= amount:
		current_health = 0
		update_remote_health.rpc(current_health)
		health_bar.set_value(current_health)
		health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")
		Global.player_died.emit()
		return
	current_health -= amount
	if current_health > max_health:
		current_health = max_health
	update_remote_health.rpc(current_health)
	health_bar.set_value((100 * current_health) / max_health)
	health_text.set_text("[center]" + str(current_health).pad_decimals(0) + "[/center]")


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
