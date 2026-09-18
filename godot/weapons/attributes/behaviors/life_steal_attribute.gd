extends AttributeClass
class_name LifeStealAttributeClass


@export var orbScene : PackedScene

#------------------------#

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if not weapon.wielder:
		return
	var health : HealthComponentClass = weapon.wielder.get("healthComponent") as HealthComponentClass
	if health:
		health.heal(damage * roll.get_value(weapon.get_attribute_level()))
	if orbScene and hurtbox and Vfx.can_spawn(orbScene, hurtbox.global_position, Vfx.effectsPerCrowd):
		var orb : LifeOrbClass = orbScene.instantiate()
		orb.position = hurtbox.global_position
		orb.target = weapon.wielder
		weapon.get_tree().current_scene.add_child(orb)
