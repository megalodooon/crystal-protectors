extends AttributeClass
class_name StatusAttributeClass


@export var element : StatusOnHitEffectClass

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	return element and element.status and super(weapon, chosen)

func get_status() -> StatusEffectClass:
	if not element:
		return null
	return element.status

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.STATUS_DAMAGE or usedStat == Stat.STATUS_DURATION or super(usedStat)

func get_aura_scene() -> PackedScene:
	if auraScene:
		return auraScene
	return element.auraScene

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var status : StatusEffectClass = element.status.duplicate()
	status.set_damage(weapon.damage * weapon.get_status_power() * roll.get_value(weapon.get_attribute_level()))
	weapon.add_hit_status(status)
