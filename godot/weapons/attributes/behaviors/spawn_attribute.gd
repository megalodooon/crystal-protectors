extends AttributeClass
class_name SpawnAttributeClass


enum Placement { TARGET, WIELDER }

@export var spawnScene : PackedScene
@export var placement : Placement = Placement.TARGET
@export var radius : float = 24.0
@export var duration : float = 2.0
@export var damageType : DamageTypeClass
@export var offset : Vector2 = Vector2.ZERO

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_AREA or usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["duration"] = AttributeScalingClass.format_number(duration)
	return values

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var holder : Node2D = weapon.get_visual_holder()
	if placement == Placement.WIELDER:
		for child in holder.get_children():
			var existing : WeaponSpawnClass = child as WeaponSpawnClass
			if existing and existing.scene_file_path == spawnScene.resource_path and existing.is_active():
				existing.refresh(duration)
				return
	var value : float = roll.get_value(weapon.get_attribute_level()) * weapon.get_effect_damage_multiplier()
	var spawn : WeaponSpawnClass = spawnScene.instantiate()
	spawn.radius = radius * weapon.get_area_multiplier()
	spawn.duration = duration
	spawn.value = value
	spawn.damage = weapon.get_damage() * value
	spawn.damageType = damageType
	if not spawn.damageType:
		spawn.damageType = weapon.damageType
	spawn.critChance = weapon.get_crit_chance()
	spawn.critMultiplier = weapon.get_crit_multiplier()
	spawn.color = weapon.get_color()
	spawn.target = hurtbox
	if placement == Placement.WIELDER:
		spawn.position = offset
		holder.add_child(spawn)
		return
	spawn.position = weapon.get_origin() + offset
	if hurtbox:
		spawn.position = hurtbox.global_position + offset
	weapon.get_tree().current_scene.add_child(spawn)
