extends StatusEffectClass
class_name WetEffectClass


@export_range(0.0, 1.0) var slowAmount : float = 0.15
@export var amplifiedType : DamageTypeClass
@export var amplifiedBonus : float = 0.25

#------------------------#

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newWet : WetEffectClass = newEffect as WetEffectClass
	if newWet:
		amplifiedBonus = maxf(amplifiedBonus, newWet.amplifiedBonus)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherWet : WetEffectClass = other as WetEffectClass
	if otherWet:
		amplifiedBonus = maxf(amplifiedBonus, otherWet.amplifiedBonus)

func set_strength(amount : float) -> void:
	amplifiedBonus = amount

func get_damage_taken_multiplier(damageType : DamageTypeClass) -> float:
	if damageType and damageType == amplifiedType:
		return 1.0 + amplifiedBonus
	return 1.0

func get_speed_multiplier() -> float:
	return 1.0 - slowAmount
