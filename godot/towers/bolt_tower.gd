extends TowerClass
class_name BoltTowerClass


@export var boltScene : PackedScene
@export var boltColor : Color = Color(0.45, 0.85, 1.0)
@export var boltSpeed : float = 110.0
@export var spread : float = 0.25

@export_group("Tier")
@export var boltsPerTier : PackedInt32Array = PackedInt32Array([1, 2, 3])
@export var piercePerTier : PackedInt32Array = PackedInt32Array([1, 1, 3])
@export var status : StatusEffectClass
@export var statusFromTier : int = 3

@onready var muzzle : Sprite2D = $Visuals/Muzzle

var muzzleFlash : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	muzzleFlash = move_toward(muzzleFlash, 0.0, delta * 5.0)
	muzzle.scale = Vector2.ONE * (0.2 + muzzleFlash * 0.25)
	muzzle.self_modulate.a = muzzleFlash * 0.8

func attack() -> bool:
	var bolts : int = get_tier_value(boltsPerTier, 1)
	var targets : Array[HurtboxComponentClass] = HurtboxComponentClass.find_in_radius(get_world_2d(), global_position, get_range(), targetLayer, bolts)
	if targets.is_empty() or not boltScene:
		return false
	for i in bolts:
		fire(targets[i % targets.size()], i)
	muzzleFlash = 1.0
	return true

func fire(target : HurtboxComponentClass, index : int) -> void:
	var bolt : ProjectileClass = boltScene.instantiate()
	bolt.damage = get_damage()
	bolt.damageType = stats.damageType
	bolt.speed = boltSpeed
	bolt.maxHits = get_tier_value(piercePerTier, 1)
	bolt.color = boltColor
	bolt.position = muzzle.global_position
	bolt.rotation = muzzle.global_position.angle_to_point(target.global_position)
	if index > 0:
		bolt.rotation += randf_range(-spread, spread)
	if status and tier >= statusFromTier:
		bolt.hit.connect(on_bolt_hit)
	get_tree().current_scene.add_child(bolt)

func on_bolt_hit(hurtbox : HurtboxComponentClass, _damage : float) -> void:
	hurtbox.apply_status(status.duplicate())

func get_color() -> Color:
	return boltColor
