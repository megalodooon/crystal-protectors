extends Area2D
class_name HitboxComponentClass


signal hit(hurtbox : HurtboxComponentClass, damage : float)

@export var damage : float = 10.0
@export var damageType : DamageTypeClass
@export_range(0.0, 1.0) var critChance : float = 0.0
@export var critMultiplier : float = 2.0
@export var maxHits : int = 0

var damageModifier : Callable
var hitCount : int = 0
var pendingHurtboxes : Array[HurtboxComponentClass] = []

#------------------------#

func _ready() -> void:
	area_entered.connect(on_area_entered)

func on_area_entered(area : Area2D) -> void:
	var hurtbox : HurtboxComponentClass = area as HurtboxComponentClass
	if not hurtbox:
		return
	if pendingHurtboxes.is_empty():
		resolve_hits.call_deferred()
	pendingHurtboxes.append(hurtbox)

func resolve_hits() -> void:
	pendingHurtboxes.sort_custom(is_closer)
	for hurtbox in pendingHurtboxes:
		if maxHits > 0 and hitCount >= maxHits:
			break
		if is_instance_valid(hurtbox):
			hit_hurtbox(hurtbox)
	pendingHurtboxes.clear()

func is_closer(a : HurtboxComponentClass, b : HurtboxComponentClass) -> bool:
	if not is_instance_valid(a) or not is_instance_valid(b):
		return is_instance_valid(a)
	return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)

func hit_hurtbox(hurtbox : HurtboxComponentClass) -> void:
	hitCount += 1
	var isCrit : bool = randf() < critChance
	var finalDamage : float = damage
	if damageModifier.is_valid():
		finalDamage = damageModifier.call(hurtbox, finalDamage)
	if isCrit:
		finalDamage *= critMultiplier
	hurtbox.take_damage(finalDamage, damageType, isCrit)
	hit.emit(hurtbox, finalDamage)
