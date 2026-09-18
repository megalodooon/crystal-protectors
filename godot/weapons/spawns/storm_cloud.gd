extends WeaponSpawnClass
class_name StormCloudClass


const LIGHTNING_SCENE := preload("res://vfx/effects/lightning.tscn")

@export var cloudHeight : float = 28.0
@export var boltColor : Color = Color(0.7, 0.85, 1.0)
@export var strikeScene : PackedScene

@onready var flash : Sprite2D = $Visuals/Flash

var flashStrength : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	super(delta)
	flashStrength = move_toward(flashStrength, 0.0, delta * 5.0)
	flash.self_modulate.a = flashStrength

func on_tick() -> void:
	var targets : Array[HurtboxComponentClass] = get_targets(global_position, radius)
	if targets.is_empty():
		return
	var hurtbox : HurtboxComponentClass = targets.pick_random()
	var lightning : LightningClass = LIGHTNING_SCENE.instantiate()
	lightning.points = PackedVector2Array([global_position + Vector2(randf_range(-7.0, 7.0), -cloudHeight), hurtbox.global_position])
	lightning.color = boltColor
	lightning.width = 1.5
	get_tree().current_scene.add_child(lightning)
	hit(hurtbox, damage)
	spawn_vfx(strikeScene, hurtbox.global_position)
	flashStrength = 1.0
