extends AttributeClass
class_name DelayedHitAttributeClass


@export var delay : float = 0.35

#------------------------#

func uses_stat(usedStat : Stat) -> bool:
	return usedStat == Stat.EFFECT_DAMAGE or super(usedStat)

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if not hurtbox:
		return
	var hitDamage : float = damage * roll.get_value(weapon.get_attribute_level()) * weapon.get_effect_damage_multiplier()
	weapon.get_tree().create_timer(delay).timeout.connect(strike.bind(weakref(weapon), weakref(hurtbox), hitDamage))

func strike(weaponRef : WeakRef, hurtboxRef : WeakRef, hitDamage : float) -> void:
	var weapon : WeaponClass = weaponRef.get_ref() as WeaponClass
	var hurtbox : HurtboxComponentClass = hurtboxRef.get_ref() as HurtboxComponentClass
	if not weapon or not hurtbox:
		return
	hurtbox.take_damage(hitDamage, weapon.damageType)
	spawn_effect(weapon, hurtbox.global_position)
