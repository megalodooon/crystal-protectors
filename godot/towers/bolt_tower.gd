extends TowerClass
class_name BoltTowerClass


@export var boltScene : PackedScene
@export var boltColor : Color = Color(0.45, 0.85, 1.0)
@export var boltSpeed : float = 110.0

@onready var muzzle : Node2D = $Visuals/Muzzle

var muzzleFlash : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	muzzleFlash = move_toward(muzzleFlash, 0.0, delta * 5.0)
	muzzle.scale = Vector2.ONE * (0.2 + muzzleFlash * 0.25)
	muzzle.self_modulate.a = muzzleFlash * 0.8

func attack() -> bool:
	var target : HurtboxComponentClass = get_closest_target()
	if not target or not boltScene:
		return false
	var bolt : ProjectileClass = boltScene.instantiate()
	bolt.damage = get_damage()
	bolt.damageType = stats.damageType
	bolt.speed = boltSpeed
	bolt.maxHits = 1
	bolt.color = boltColor
	bolt.position = muzzle.global_position
	bolt.rotation = muzzle.global_position.angle_to_point(target.global_position)
	get_tree().current_scene.add_child(bolt)
	muzzleFlash = 1.0
	return true

func get_color() -> Color:
	return boltColor
