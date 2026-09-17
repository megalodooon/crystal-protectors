extends AttributeClass
class_name StatusBoostAttributeClass


@export var includeDebuffs : bool = false

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	if not super(weapon, chosen):
		return false
	if not StatusAttributeClass.get_statuses(weapon, chosen).is_empty():
		return true
	if includeDebuffs:
		for attribute in chosen:
			if attribute is DebuffAttributeClass:
				return true
	return false
