extends AttributeClass
class_name TradeoffAttributeClass


@export var secondStat : Stat = Stat.NONE
@export var secondScaling : AttributeScalingClass
@export var requiredStat : Stat = Stat.NONE

#------------------------#

func can_roll(weapon : WeaponClass, chosen : Array[AttributeClass]) -> bool:
	return super(weapon, chosen) and (requiredStat == Stat.NONE or is_stat_used(weapon, chosen, requiredStat))

func get_stat_bonus(bonusStat : Stat, quality : float, level : int) -> float:
	var bonus : float = super(bonusStat, quality, level)
	if bonusStat != Stat.NONE and bonusStat == secondStat and secondScaling:
		bonus += secondScaling.get_value(quality, level)
	return bonus

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	if secondScaling:
		values["second"] = secondScaling.format_value(secondScaling.get_value(quality, level))
	return values
