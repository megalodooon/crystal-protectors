extends StatusEffectClass
class_name ModifierEffectClass


@export var damageTaken : float = 1.0
@export var speed : float = 1.0
@export var regeneration : float = 0.0

#------------------------#

func on_tick() -> void:
	if regeneration <= 0.0 or not status.hurtbox or not status.hurtbox.healthComponent:
		return
	var health : HealthComponentClass = status.hurtbox.healthComponent
	if health.currentHealth <= 0.0 or health.currentHealth >= health.maxHealth:
		return
	health.heal(health.maxHealth * regeneration * tickInterval)
	pulse_visual()

func get_damage_taken_multiplier(_damageType : DamageTypeClass) -> float:
	return damageTaken

func get_speed_multiplier() -> float:
	return speed
