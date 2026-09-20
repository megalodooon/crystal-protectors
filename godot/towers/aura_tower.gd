extends TowerClass
class_name AuraTowerClass


@export var pulseScene : PackedScene
@export var status : StatusEffectClass
@export var auraColor : Color = Color(1.0, 0.55, 0.15)

@onready var ring : Sprite2D = $Visuals/Ring

#------------------------#

func _ready() -> void:
	super()
	ring.self_modulate = Color(auraColor, ring.self_modulate.a)
	ring.scale = Vector2.ONE * get_range() * 2.0 / float(ring.texture.get_width())

func attack() -> bool:
	var targets : Array[HurtboxComponentClass] = get_targets()
	if targets.is_empty():
		return false
	for target in targets:
		target.take_damage(get_damage(), stats.damageType)
		if status:
			target.apply_status(status.duplicate())
	Vfx.spawn_effect(pulseScene, global_position, get_range(), auraColor)
	return true

func get_color() -> Color:
	return auraColor
