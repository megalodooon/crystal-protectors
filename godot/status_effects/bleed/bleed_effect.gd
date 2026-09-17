extends StatusEffectClass
class_name BleedEffectClass


@export var totalDamage : float = 10.0
@export var damageType : DamageTypeClass

var remainingDamage : float = 0.0

#------------------------#

func on_apply() -> void:
	remainingDamage = totalDamage

func on_tick() -> void:
	var ticksLeft : int = maxi(ceili(timeLeft / tickInterval), 1)
	var tickDamage : float = remainingDamage / ticksLeft
	remainingDamage -= tickDamage
	if status.hurtbox and tickDamage > 0.0:
		status.hurtbox.take_damage(tickDamage, damageType)

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newBleed : BleedEffectClass = newEffect as BleedEffectClass
	if newBleed:
		remainingDamage += newBleed.totalDamage

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherBleed : BleedEffectClass = other as BleedEffectClass
	if otherBleed:
		totalDamage += otherBleed.totalDamage

func scale_power(multiplier : float) -> void:
	totalDamage *= multiplier

func set_damage(amount : float) -> void:
	totalDamage = amount
