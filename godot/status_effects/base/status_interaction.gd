extends Resource
class_name StatusInteractionClass


@export var triggerEffects : Array[String]
@export var triggerDamageTypes : Array[DamageTypeClass]
@export var blockTriggerEffect : bool = false

#------------------------#

func trigger(_effect : StatusEffectClass) -> void:
	pass
