extends StatBoostAttributeClass
class_name StatusTargetDamageAttributeClass


@export var effectNames : Array[String]

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	if not super(weapon, chosen):
		return false
	if effectNames.is_empty():
		return true
	for status in get_statuses(weapon, chosen):
		if effectNames.has(status.effectName):
			return true
	return false

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	if not has_matching_status(hurtbox):
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))

func has_matching_status(hurtbox : HurtboxComponentClass) -> bool:
	if not hurtbox.statusComponent:
		return false
	if effectNames.is_empty():
		return not hurtbox.statusComponent.get_harmful_effects().is_empty()
	for effectName in effectNames:
		if hurtbox.statusComponent.has_effect(effectName):
			return true
	return false
