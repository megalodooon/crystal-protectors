extends StatusEffectClass
class_name FrostEffectClass


@export var stacksToProc : int = 4
@export var frostbiteDamage : float = 20.0
@export var damageType : DamageTypeClass
@export var frostbiteScene : PackedScene

var stacks : int = 0

#------------------------#

func on_apply() -> void:
	add_stack()

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newFrost : FrostEffectClass = newEffect as FrostEffectClass
	if newFrost:
		frostbiteDamage = maxf(frostbiteDamage, newFrost.frostbiteDamage)
	add_stack()

func scale_power(multiplier : float) -> void:
	frostbiteDamage *= multiplier

func add_stack() -> void:
	stacks += 1
	if visual:
		visual.modulate.a = float(stacks) / stacksToProc
	if stacks >= stacksToProc:
		frostbite()

func frostbite() -> void:
	if status.hurtbox:
		status.hurtbox.take_damage(frostbiteDamage, damageType)
	if frostbiteScene:
		status.get_visual_parent().add_child(frostbiteScene.instantiate())
	status.remove_effect(self)
