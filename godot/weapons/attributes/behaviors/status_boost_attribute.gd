extends AttributeClass
class_name StatusBoostAttributeClass


#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	return super(weapon, chosen) and not StatusAttributeClass.get_statuses(weapon, chosen).is_empty()
