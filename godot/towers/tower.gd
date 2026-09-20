extends StaticBody2D
class_name TowerClass


signal changed

const BUILD_EFFECT := preload("res://vfx/effects/cast_flash.tscn")
const BREAK_EFFECT := preload("res://vfx/effects/crystal_shatter.tscn")

@export var healthComponent : HealthComponentClass
@export var barFill : Sprite2D
@export var barBack : Sprite2D
@export var rangeHint : Sprite2D
@export_flags_2d_physics var targetLayer : int = 16
@export var buildTime : float = 0.3
@export var barWidth : float = 12.0

@onready var visuals : Node2D = $Visuals
@onready var collisionShape : CollisionShape2D = $CollisionShape2D

var stats : TowerStatsClass
var tier : int = 1
var isPreview : bool = false
var cooldown : float = 0.0

#------------------------#

func _ready() -> void:
	if rangeHint:
		rangeHint.visible = isPreview
		rangeHint.scale = Vector2.ONE * get_range() * 2.0 / float(rangeHint.texture.get_width())
	if isPreview:
		collisionShape.disabled = true
		set_physics_process(false)
		barFill.visible = false
		barBack.visible = false
		return
	healthComponent.maxHealth = stats.get_health(tier)
	healthComponent.currentHealth = healthComponent.maxHealth
	healthComponent.health_changed.connect(on_health_changed)
	healthComponent.died.connect(destroy)
	update_bar()
	set_physics_process(get_range() > 0.0)
	Vfx.spawn_effect(BUILD_EFFECT, global_position, get_range(), get_color())
	pop_visuals(Vector2(1.3, 0.6))

func _physics_process(delta : float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return
	if attack():
		cooldown = stats.attackCooldown

func set_valid(value : bool) -> void:
	modulate = Color(0.6, 1.0, 0.7, 0.6) if value else Color(1.0, 0.45, 0.45, 0.5)

func attack() -> bool:
	return false

func take_damage(amount : float) -> void:
	healthComponent.take_damage(amount)

func repair() -> void:
	healthComponent.currentHealth = healthComponent.maxHealth
	healthComponent.health_changed.emit(healthComponent.currentHealth, healthComponent.maxHealth)

func upgrade() -> void:
	tier += 1
	healthComponent.maxHealth = stats.get_health(tier)
	repair()
	pop_visuals(Vector2(1.25, 1.25))
	Vfx.spawn_effect(BUILD_EFFECT, global_position, get_range(), get_color())
	changed.emit()

func destroy() -> void:
	Vfx.spawn_effect(BREAK_EFFECT, global_position, 14.0, get_color())
	queue_free()

func pop_visuals(from : Vector2) -> void:
	visuals.scale = from
	create_tween().tween_property(visuals, "scale", Vector2.ONE, buildTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_missing_health() -> float:
	return 1.0 - healthComponent.currentHealth / healthComponent.maxHealth

func get_damage() -> float:
	return stats.get_damage(tier)

func get_range() -> float:
	return stats.attackRange

func get_color() -> Color:
	return Color.WHITE

func get_targets() -> Array[HurtboxComponentClass]:
	return HurtboxComponentClass.find_in_radius(get_world_2d(), global_position, get_range(), targetLayer, stats.maxTargets)

func get_closest_target() -> HurtboxComponentClass:
	var targets : Array[HurtboxComponentClass] = HurtboxComponentClass.find_in_radius(get_world_2d(), global_position, get_range(), targetLayer, 1)
	if targets.is_empty():
		return null
	return targets[0]

func on_health_changed(_currentHealth : float, _maxHealth : float) -> void:
	update_bar()
	changed.emit()

func update_bar() -> void:
	var fraction : float = healthComponent.currentHealth / healthComponent.maxHealth
	barFill.scale.x = barWidth * fraction / float(barFill.texture.get_width())
	barFill.position.x = (fraction - 1.0) * barWidth / 2.0
	barFill.modulate = Color(0.35, 0.9, 0.45).lerp(Color(0.95, 0.3, 0.25), 1.0 - fraction)
	barFill.visible = fraction < 0.999
	barBack.visible = barFill.visible
