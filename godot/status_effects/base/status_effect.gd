extends Resource
class_name StatusEffectClass


@export var effectName : String
@export var duration : float = 3.0
@export var tickInterval : float = 0.5
@export var visualScene : PackedScene

var status : StatusComponentClass
var timeLeft : float = 0.0
var tickTimer : float = 0.0
var visual : Node2D

#------------------------#

func update(delta : float) -> void:
	timeLeft -= delta
	if tickInterval <= 0.0:
		return
	tickTimer += delta
	while tickTimer >= tickInterval:
		tickTimer -= tickInterval
		on_tick()

func refresh(newEffect : StatusEffectClass) -> void:
	timeLeft = maxf(timeLeft, newEffect.duration)

func on_apply() -> void:
	pass

func on_tick() -> void:
	pass

func on_remove() -> void:
	pass
