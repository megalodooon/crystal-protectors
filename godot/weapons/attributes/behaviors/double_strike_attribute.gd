extends AttributeClass
class_name DoubleStrikeAttributeClass


@export var delay : float = 0.12

#------------------------#

func on_attack(weapon : WeaponClass, roll : AttributeRollClass) -> void:
	if randf() >= roll.get_value(weapon.get_attribute_level()):
		return
	weapon.get_tree().create_timer(delay).timeout.connect(strike_again.bind(weakref(weapon)))

func strike_again(weaponRef : WeakRef) -> void:
	var weapon : WeaponClass = weaponRef.get_ref() as WeaponClass
	if not weapon:
		return
	for attackNode in weapon.get_attacks():
		if can_use_attack(attackNode):
			attackNode.perform()
