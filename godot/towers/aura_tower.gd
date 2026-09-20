extends TowerClass
class_name AuraTowerClass


@export var auraColor : Color = Color(1.0, 0.55, 0.15)
@export var ringAlpha : float = 0.13

@export_group("Tier")
@export var status : StatusEffectClass
@export var statusFromTier : int = 2
@export var eruptScene : PackedScene
@export var eruptFromTier : int = 3
@export var eruptEvery : int = 4
@export var eruptDamage : float = 3.0
@export var eruptRadius : float = 1.6

@onready var ring : Sprite2D = $Visuals/Ring

var tickCount : int = 0
var ringFlash : float = 0.0

#------------------------#

func _ready() -> void:
	super()
	ring.self_modulate = Color(auraColor, ringAlpha)
	ring.scale = Vector2.ONE * get_range() * 2.0 / float(ring.texture.get_width())

func _process(delta : float) -> void:
	ringFlash = move_toward(ringFlash, 0.0, delta * 3.0)
	ring.self_modulate.a = ringAlpha * (1.0 + ringFlash * 2.5)

func attack() -> bool:
	var erupting : bool = tier >= eruptFromTier and (tickCount + 1) % eruptEvery == 0
	var radius : float = get_range() * (eruptRadius if erupting else 1.0)
	var targets : Array[HurtboxComponentClass] = HurtboxComponentClass.find_in_radius(get_world_2d(), global_position, radius, targetLayer, stats.maxTargets)
	if targets.is_empty():
		return false
	tickCount += 1
	var damage : float = get_damage() * (eruptDamage if erupting else 1.0)
	for target in targets:
		target.take_damage(damage, stats.damageType)
		if status and tier >= statusFromTier:
			target.apply_status(status.duplicate())
	ringFlash = 1.0
	if erupting:
		Vfx.spawn_effect(eruptScene, global_position, radius, auraColor)
	return true

func get_color() -> Color:
	return auraColor
