extends AttributeClass
class_name AreaDamageAttributeClass


const SHOCKWAVE_SCENE := preload("res://vfx/shockwave/shockwave.tscn")

@export var radius : float = 20.0
@export var onKill : bool = false

#------------------------#

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if not onKill:
		explode(weapon, hurtbox, damage * roll.get_value(weapon.get_attribute_level()))

func on_kill(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> void:
	if onKill:
		explode(weapon, hurtbox, damage * roll.get_value(weapon.get_attribute_level()))

func explode(weapon : WeaponClass, hurtbox : HurtboxComponentClass, areaDamage : float) -> void:
	for target in get_hurtboxes_in_radius(weapon, hurtbox.global_position, radius, hurtbox.collision_layer):
		if target != hurtbox:
			target.take_damage(areaDamage, weapon.damageType)
	var shockwave : ShockwaveClass = SHOCKWAVE_SCENE.instantiate()
	shockwave.position = hurtbox.global_position
	shockwave.radius = radius
	shockwave.color = weapon.get_color()
	weapon.get_tree().current_scene.add_child(shockwave)
