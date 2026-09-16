extends AttributeClass
class_name StatusAttributeClass


@export var element : StatusOnHitEffectClass

#------------------------#

static func get_statuses(weapon : WeaponClass, chosen : Array[AttributeClass]) -> Array[StatusEffectClass]:
	var statuses : Array[StatusEffectClass] = []
	var weaponEffects : Array[WeaponEffectClass] = weapon.effects.duplicate()
	if weapon.rarity:
		weaponEffects.append_array(weapon.rarity.effects)
	for effect in weaponEffects:
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

func on_equip(weapon : WeaponClass, _roll : AttributeRollClass) -> void:
	for effect in weapon.activeEffects:
		var statusEffect : StatusOnHitEffectClass = effect as StatusOnHitEffectClass
		if statusEffect and statusEffect.auraScene == element.auraScene:
			return
	element.on_equip(weapon)

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var status : StatusEffectClass = element.status.duplicate()
	status.set_damage(weapon.damage * weapon.get_status_power() * roll.get_value(weapon.get_attribute_level()))
	weapon.add_hit_status(status)
