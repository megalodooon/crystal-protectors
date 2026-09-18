extends Resource
class_name WeaponEffectClass


#------------------------#

func uses_stat(_stat : AttributeClass.Stat) -> bool:
	return false

func get_status() -> StatusEffectClass:
	return null

func on_equip(_weapon : WeaponClass) -> void:
	pass

func on_attack(_weapon : WeaponClass) -> void:
	pass

func on_hit(_weapon : WeaponClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	pass
