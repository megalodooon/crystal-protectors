extends AttributeClass
class_name NearbyEnemiesDamageAttributeClass


enum Mode { ISOLATED, PER_ENEMY }

@export var mode : Mode = Mode.ISOLATED
@export var radius : float = 28.0
@export var maxEnemies : int = 5

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["max"] = str(maxEnemies)
	return values

func modify_hit_damage(weapon : WeaponClass, roll : AttributeRollClass, hurtbox : HurtboxComponentClass, damage : float) -> float:
	var others : int = get_hurtboxes_in_radius(weapon, hurtbox.global_position, radius, hurtbox.collision_layer).size() - 1
	var value : float = roll.get_value(weapon.get_attribute_level())
	if mode == Mode.ISOLATED:
		if others > 0:
			return damage
		return damage * (1.0 + value)
	return damage * (1.0 + value * clampi(others, 0, maxEnemies))
