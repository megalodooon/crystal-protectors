extends Node2D
class_name BuffVisualClass


@export var tiers : Array[CPUParticles2D]
@export var minAlpha : float = 0.55
@export var fadeTime : float = 0.35

var active : bool = true

#------------------------#

func set_stacks(stacks : int, maxStacks : int) -> void:
	var intensity : float = 1.0
	if maxStacks > 1:
		intensity = float(stacks - 1) / (maxStacks - 1)
	modulate.a = lerpf(minAlpha, 1.0, intensity)
	for i in tiers.size():
		tiers[i].emitting = active and intensity >= float(i) / tiers.size()

func stop() -> void:
	active = false
	for child in find_children("*", "CPUParticles2D", true, false):
		child.emitting = false
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fadeTime)
	tween.tween_interval(0.8)
	tween.tween_callback(queue_free)
