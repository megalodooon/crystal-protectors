extends AttributeClass
class_name StatBoostAttributeClass


@export var requiredStat : Stat = Stat.NONE

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	var usedStat : Stat = requiredStat
	if usedStat == Stat.NONE:
		usedStat = stat
	return super(weapon, chosen) and is_stat_used(weapon, chosen, usedStat)
