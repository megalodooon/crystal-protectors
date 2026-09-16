extends Area2D
class_name HitboxComponentClass


signal hit(hurtbox : HurtboxComponentClass, damage : float)

@export var damage : float = 10.0
@export var damageType : DamageTypeClass
@export_range(0.0, 1.0) var critChance : float = 0.0
@export var critMultiplier : float = 2.0

#------------------------#

func _ready() -> void:
	area_entered.connect(on_area_entered)

func on_area_entered(area : Area2D) -> void:
	if area is HurtboxComponentClass:
		var isCrit : bool = randf() < critChance
		var finalDamage : float = damage
		if isCrit:
			finalDamage *= critMultiplier
		area.take_damage(finalDamage, damageType, isCrit)
		hit.emit.call_deferred(area, finalDamage)
