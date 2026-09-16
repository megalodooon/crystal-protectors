extends StatusEffectClass
class_name BurnEffectClass


@export var damagePerTick : float = 2.0
@export var damageType : DamageTypeClass

#------------------------#

func on_tick() -> void:
	if status.hurtbox:
		status.hurtbox.take_damage(damagePerTick, damageType)

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newBurn : BurnEffectClass = newEffect as BurnEffectClass
	if newBurn:
		damagePerTick = maxf(damagePerTick, newBurn.damagePerTick)

func scale_power(multiplier : float) -> void:
	damagePerTick *= multiplier
