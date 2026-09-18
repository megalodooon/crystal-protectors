extends StatusEffectClass
class_name SunderEffectClass


@export var damageTakenBonus : float = 0.1

#------------------------#

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newSunder : SunderEffectClass = newEffect as SunderEffectClass
	if newSunder:
		damageTakenBonus = maxf(damageTakenBonus, newSunder.damageTakenBonus)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherSunder : SunderEffectClass = other as SunderEffectClass
	if otherSunder:
		damageTakenBonus += otherSunder.damageTakenBonus

func set_strength(amount : float) -> void:
	damageTakenBonus = amount

func get_damage_taken_multiplier(_damageType : DamageTypeClass) -> float:
	return 1.0 + damageTakenBonus
