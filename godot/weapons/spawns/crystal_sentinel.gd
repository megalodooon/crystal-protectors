extends WeaponSpawnClass
class_name CrystalSentinelClass


@export var boltScene : PackedScene
@export var boltColor : Color = Color(1.0, 0.5, 0.9)
@export var bobHeight : float = 1.5

@onready var visuals : Node2D = $Visuals
@onready var muzzle : Sprite2D = $Visuals/Muzzle

var muzzleStrength : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	super(delta)
	visuals.position.y = sin(age * 3.0) * bobHeight
	muzzleStrength = move_toward(muzzleStrength, 0.0, delta * 6.0)
	muzzle.self_modulate.a = muzzleStrength

func on_tick() -> void:
	var closest : HurtboxComponentClass = get_closest_target(global_position, radius)
	if not closest or not boltScene:
		return
	var from : Vector2 = muzzle.global_position
	var bolt : ProjectileClass = boltScene.instantiate()
	bolt.damage = damage
	bolt.damageType = damageType
	bolt.critChance = critChance
	bolt.critMultiplier = critMultiplier
	bolt.maxHits = 1
	bolt.color = boltColor
	bolt.position = from
	bolt.rotation = from.angle_to_point(closest.global_position)
	get_tree().current_scene.add_child(bolt)
	muzzleStrength = 1.0
