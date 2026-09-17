extends AttributeClass
class_name ZoneAttributeClass


@export var zoneScene : PackedScene
@export var status : StatusEffectClass
@export var radius : float = 28.0

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	if usedStat == Stat.EFFECT_AREA or usedStat == Stat.STATUS_DAMAGE or usedStat == Stat.STATUS_DURATION:
		return true
	return super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var zone : StatusZoneClass = zoneScene.instantiate()
	zone.position = weapon.get_origin()
	if hurtbox:
		zone.position = hurtbox.global_position
	zone.radius = radius * weapon.get_area_multiplier()
	var zoneStatus : StatusEffectClass = status.duplicate()
	zoneStatus.set_damage(weapon.damage * weapon.get_status_power() * roll.get_value(weapon.get_attribute_level()))
	zoneStatus.duration *= 1.0 + weapon.get_stat(Stat.STATUS_DURATION)
	zone.status = zoneStatus
	weapon.get_tree().current_scene.add_child(zone)
