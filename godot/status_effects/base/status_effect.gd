extends Resource
class_name StatusEffectClass


@export var effectName : String
@export var duration : float = 3.0
@export var tickInterval : float = 0.5
@export var permanent : bool = false
@export var beneficial : bool = false
@export var visualScene : PackedScene
@export var interactions : Array[StatusInteractionClass]

var status : StatusComponentClass
var timeLeft : float = 0.0
var tickTimer : float = 0.0
var visual : Node2D

#------------------------#

func update(delta : float) -> void:
	if not permanent:
		timeLeft -= delta
	if tickInterval <= 0.0:
		return
	tickTimer += delta
	while tickTimer >= tickInterval:
		tickTimer -= tickInterval
		on_tick()

func refresh(newEffect : StatusEffectClass) -> void:
	timeLeft = maxf(timeLeft, newEffect.duration)

func combine(other : StatusEffectClass) -> void:
	duration = maxf(duration, other.duration)

func scale_power(_multiplier : float) -> void:
	pass

func set_damage(_amount : float) -> void:
	pass

func set_strength(_amount : float) -> void:
	pass

func get_remaining_damage() -> float:
	return 0.0

func get_damage_taken_multiplier(_damageType : DamageTypeClass) -> float:
	return 1.0

func get_speed_multiplier() -> float:
	return 1.0

func pulse_visual() -> void:
	var statusVisual : StatusVisualClass = visual as StatusVisualClass
	if statusVisual:
		statusVisual.pulse()

func on_apply() -> void:
	pass

func on_tick() -> void:
	pass

func on_remove() -> void:
	pass

func on_damage_taken(_amount : float, _damageType : DamageTypeClass) -> void:
	pass
