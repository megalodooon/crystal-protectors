extends AttributeClass
class_name MovementDamageAttributeClass


@export var whileMoving : bool = true
@export var minSpeed : float = 5.0

#------------------------#

func modify_attack_damage(weapon : WeaponClass, roll : AttributeRollClass, damage : float) -> float:
	var body : CharacterBody2D = weapon.wielder as CharacterBody2D
	if not body or (body.velocity.length() > minSpeed) != whileMoving:
		return damage
	return damage * (1.0 + roll.get_value(weapon.get_attribute_level()))
