extends AttributeClass
class_name DebuffAttributeClass


@export var status : StatusEffectClass
@export var valueIsChance : bool = false

#------------------------#

func get_description_values(quality : float, level : int) -> Dictionary:
	var values : Dictionary = super(quality, level)
	values["duration"] = AttributeScalingClass.format_number(status.duration)
	return values

func on_hit(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	var value : float = roll.get_value(weapon.get_attribute_level())
	if valueIsChance and randf() >= value:
		return
	var newStatus : StatusEffectClass = status.duplicate()
	if not valueIsChance:
		newStatus.set_strength(value)
	weapon.add_hit_status(newStatus)
