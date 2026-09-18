extends Node
class_name StatusComponentClass


signal effect_added(effect : StatusEffectClass)
signal effect_removed(effect : StatusEffectClass)

@export var hurtbox : HurtboxComponentClass
@export var sprite : Sprite2D
@export var visualParent : Node2D

var activeEffects : Dictionary[String, StatusEffectClass] = {}

#------------------------#

func _ready() -> void:
	set_process(false)

func _process(delta : float) -> void:
	if activeEffects.is_empty():
		set_process(false)
		return
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
		var existing : StatusEffectClass = activeEffects[effect.effectName]
		existing.refresh(effect)
		existing.pulse_visual()
		return
	var newEffect : StatusEffectClass = effect.duplicate()
	newEffect.status = self
	newEffect.timeLeft = newEffect.duration
	activeEffects[newEffect.effectName] = newEffect
	set_process(true)
	if newEffect.visualScene and Vfx.add_status_visual(newEffect):
		create_visual(newEffect, true)
	newEffect.on_apply()
	effect_added.emit(newEffect)

func create_visual(effect : StatusEffectClass, playBurst : bool) -> void:
	effect.visual = effect.visualScene.instantiate()
	var statusVisual : StatusVisualClass = effect.visual as StatusVisualClass
	if statusVisual:
		statusVisual.skipBurst = not playBurst
	get_visual_parent().add_child(effect.visual)
	effect.on_visual_created()

func set_visual_shown(effect : StatusEffectClass, shown : bool) -> void:
	if shown and not effect.visual:
		create_visual(effect, false)
	if effect.visual:
		effect.visual.visible = shown
		effect.visual.process_mode = Node.PROCESS_MODE_INHERIT if shown else Node.PROCESS_MODE_DISABLED

func on_damage_taken(amount : float, damageType : DamageTypeClass) -> void:
	for active : StatusEffectClass in activeEffects.values():
		active.on_damage_taken(amount, damageType)
		if not damageType:
			continue
		for interaction : StatusInteractionClass in active.interactions:
			if interaction.triggerDamageTypes.has(damageType):
				interaction.trigger(active)

func remove_effect(effect : StatusEffectClass) -> void:
	if activeEffects.get(effect.effectName) != effect:
		return
	activeEffects.erase(effect.effectName)
	effect.on_remove()
	var statusVisual : StatusVisualClass = effect.visual as StatusVisualClass
	if statusVisual:
		statusVisual.stop()
	elif effect.visual:
		for child in effect.visual.get_children():
			if child is CPUParticles2D:
				child.emitting = false
	if effect.visual:
		get_tree().create_timer(1.0).timeout.connect(effect.visual.queue_free)
	effect_removed.emit(effect)

func has_effect(effectName : String) -> bool:
	return activeEffects.has(effectName)

func get_harmful_effects() -> Array[StatusEffectClass]:
	var harmful : Array[StatusEffectClass] = []
	for effect : StatusEffectClass in activeEffects.values():
		if not effect.beneficial:
			harmful.append(effect)
	return harmful

func get_damage_taken_multiplier(damageType : DamageTypeClass) -> float:
	var multiplier : float = 1.0
	for effect : StatusEffectClass in activeEffects.values():
		multiplier *= effect.get_damage_taken_multiplier(damageType)
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
