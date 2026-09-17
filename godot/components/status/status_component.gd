extends Node
class_name StatusComponentClass


signal effect_added(effect : StatusEffectClass)
signal effect_removed(effect : StatusEffectClass)

@export var hurtbox : HurtboxComponentClass
@export var sprite : Sprite2D
@export var visualParent : Node2D

var activeEffects : Dictionary[String, StatusEffectClass] = {}

#------------------------#

func _process(delta : float) -> void:
	for effect : StatusEffectClass in activeEffects.values():
		effect.update(delta)
		if effect.timeLeft <= 0.0:
			remove_effect(effect)

func apply_effect(effect : StatusEffectClass) -> void:
	var blocked : bool = false
	for active : StatusEffectClass in activeEffects.values():
		for interaction : StatusInteractionClass in active.interactions:
			if interaction.triggerEffects.has(effect.effectName):
				interaction.trigger(active)
				blocked = blocked or interaction.blockTriggerEffect
	if blocked:
		return
	if activeEffects.has(effect.effectName):
		activeEffects[effect.effectName].refresh(effect)
		return
	var newEffect : StatusEffectClass = effect.duplicate()
	newEffect.status = self
	newEffect.timeLeft = newEffect.duration
	activeEffects[newEffect.effectName] = newEffect
	if newEffect.visualScene:
		newEffect.visual = newEffect.visualScene.instantiate()
		get_visual_parent().add_child(newEffect.visual)
	newEffect.on_apply()
	effect_added.emit(newEffect)

func on_damage_taken(damageType : DamageTypeClass) -> void:
	if not damageType:
		return
	for active : StatusEffectClass in activeEffects.values():
		for interaction : StatusInteractionClass in active.interactions:
			if interaction.triggerDamageTypes.has(damageType):
				interaction.trigger(active)

func remove_effect(effect : StatusEffectClass) -> void:
	if activeEffects.get(effect.effectName) != effect:
		return
	activeEffects.erase(effect.effectName)
	effect.on_remove()
	if effect.visual:
		for child in effect.visual.get_children():
			if child is CPUParticles2D:
				child.emitting = false
		get_tree().create_timer(1.0).timeout.connect(effect.visual.queue_free)
	effect_removed.emit(effect)

func has_effect(effectName : String) -> bool:
	return activeEffects.has(effectName)

func get_damage_taken_multiplier() -> float:
	var multiplier : float = 1.0
	for effect : StatusEffectClass in activeEffects.values():
		multiplier *= effect.get_damage_taken_multiplier()
	return multiplier

func get_speed_multiplier() -> float:
	var multiplier : float = 1.0
	for effect : StatusEffectClass in activeEffects.values():
		multiplier *= effect.get_speed_multiplier()
	return multiplier

func get_visual_parent() -> Node2D:
	if visualParent:
		return visualParent
	return get_parent()
