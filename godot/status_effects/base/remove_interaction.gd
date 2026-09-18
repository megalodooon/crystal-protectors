extends StatusInteractionClass
class_name RemoveInteractionClass


#------------------------#

func trigger(effect : StatusEffectClass) -> void:
	effect.status.remove_effect(effect)
