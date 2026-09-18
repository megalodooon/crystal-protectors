extends StatBoostAttributeClass
class_name CatalystAttributeClass


@export var effectNames : Array[String] = ["Burn", "Poison", "Bleed"]

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not hurtbox or not hurtbox.statusComponent:
		return
	var multiplier : float = (1.0 + roll.get_value(weapon.get_attribute_level())) * weapon.get_effect_damage_multiplier()
	var detonated : bool = false
	for effect : StatusEffectClass in hurtbox.statusComponent.activeEffects.values():
		var remaining : float = effect.get_remaining_damage()
		if not effectNames.has(effect.effectName) or remaining <= 0.0:
			continue
		hurtbox.statusComponent.remove_effect(effect)
		hurtbox.take_damage(remaining * multiplier, effect.get("damageType") as DamageTypeClass)
		detonated = true
	if detonated:
		spawn_effect(weapon, hurtbox.global_position)
