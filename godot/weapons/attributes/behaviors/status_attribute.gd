extends AttributeClass
class_name StatusAttributeClass


@export var element : StatusOnHitEffectClass

#------------------------#

static func get_statuses(weapon : WeaponClass, chosen : Array[AttributeClass]) -> Array[StatusEffectClass]:
	var statuses : Array[StatusEffectClass] = []
	for effect in weapon.get_all_effects():
		var statusEffect : StatusOnHitEffectClass = effect as StatusOnHitEffectClass
		if statusEffect and statusEffect.status:
			statuses.append(statusEffect.status)
	for attribute in chosen:
		var statusAttribute : StatusAttributeClass = attribute as StatusAttributeClass
		if statusAttribute and statusAttribute.element and statusAttribute.element.status:
			statuses.append(statusAttribute.element.status)
	return statuses

static func cancels(status : StatusEffectClass, other : StatusEffectClass) -> bool:
	for interaction in status.interactions:
		if interaction.triggerEffects.has(other.effectName):
			return true
	return false

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	if not element or not element.status or not super(weapon, chosen):
		return false
	for status in get_statuses(weapon, chosen):
		if cancels(status, element.status) or cancels(element.status, status):
			return false
	return true

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
