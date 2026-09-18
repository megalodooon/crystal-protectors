extends StatusEffectClass
class_name CrystalEffectClass


@export var shatterDamage : float = 10.0
@export var shatterRadius : float = 16.0
@export var maxTargets : int = 6
@export var damageType : DamageTypeClass
@export var shatterScene : PackedScene

#------------------------#

func get_speed_multiplier() -> float:
	return 0.0

func refresh(newEffect : StatusEffectClass) -> void:
	var newCrystal : CrystalEffectClass = newEffect as CrystalEffectClass
	if newCrystal:
		shatterDamage = maxf(shatterDamage, newCrystal.shatterDamage)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherCrystal : CrystalEffectClass = other as CrystalEffectClass
	if otherCrystal:
		shatterDamage += otherCrystal.shatterDamage

func scale_power(multiplier : float) -> void:
	shatterDamage *= multiplier

func set_damage(amount : float) -> void:
	shatterDamage = amount

func on_remove() -> void:
	var hurtbox : HurtboxComponentClass = status.hurtbox
	if not is_instance_valid(hurtbox):
		return
	for target in HurtboxComponentClass.find_in_radius(hurtbox.get_world_2d(), hurtbox.global_position, shatterRadius, hurtbox.collision_layer, maxTargets):
		target.take_damage(shatterDamage, damageType)
	Vfx.spawn_effect(shatterScene, hurtbox.global_position)
