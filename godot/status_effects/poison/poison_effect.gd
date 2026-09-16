extends StatusEffectClass
class_name PoisonEffectClass


@export var damagePerStack : float = 1.0
@export var maxStacks : int = 5
@export var damageType : DamageTypeClass

var stacks : int = 0

#------------------------#

func on_apply() -> void:
	stacks = 1

func on_tick() -> void:
	if status.hurtbox:
		status.hurtbox.take_damage(damagePerStack * stacks, damageType)

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newPoison : PoisonEffectClass = newEffect as PoisonEffectClass
	if newPoison:
		damagePerStack = maxf(damagePerStack, newPoison.damagePerStack)
	stacks = mini(stacks + 1, maxStacks)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherPoison : PoisonEffectClass = other as PoisonEffectClass
	if otherPoison:
		damagePerStack += otherPoison.damagePerStack

func scale_power(multiplier : float) -> void:
	damagePerStack *= multiplier

func set_damage(amount : float) -> void:
	damagePerStack = amount
