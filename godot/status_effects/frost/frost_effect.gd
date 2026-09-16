extends StatusEffectClass
class_name FrostEffectClass


@export var stacksToProc : int = 4
@export var frostbiteDamage : float = 20.0
@export var damageType : DamageTypeClass
@export var frostbiteScene : PackedScene

var stacks : int = 0

#------------------------#

func on_apply() -> void:
	var frostVisual : FrostVisualClass = get_frost_visual()
	if frostVisual:
		frostVisual.targetSprite = status.sprite
	add_stack()

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newFrost : FrostEffectClass = newEffect as FrostEffectClass
	if newFrost:
		frostbiteDamage = maxf(frostbiteDamage, newFrost.frostbiteDamage)
	add_stack()

func scale_power(multiplier : float) -> void:
	frostbiteDamage *= multiplier

func on_remove() -> void:
	var frostVisual : FrostVisualClass = get_frost_visual()
	if frostVisual:
		frostVisual.buildUp = 0.0

func add_stack() -> void:
	stacks += 1
	var frostVisual : FrostVisualClass = get_frost_visual()
	if frostVisual:
		frostVisual.buildUp = float(stacks) / maxi(stacksToProc - 1, 1)
	if stacks >= stacksToProc:
		frostbite()

func frostbite() -> void:
	if status.hurtbox:
		status.hurtbox.take_damage(frostbiteDamage, damageType)
	if frostbiteScene:
		status.get_visual_parent().add_child(frostbiteScene.instantiate())
	var frostVisual : FrostVisualClass = get_frost_visual()
	if frostVisual:
		frostVisual.shatter()
	status.remove_effect(self)

func get_frost_visual() -> FrostVisualClass:
	return visual as FrostVisualClass
