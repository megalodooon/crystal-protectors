extends BuffAttributeClass
class_name RandomBuffAttributeClass


@export var buffStats : Array[Stat]
@export var buffScenes : Array[PackedScene]

#------------------------#

func on_proc(weapon : WeaponClass, roll : AttributeRollClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if buffStats.is_empty():
		return
	var index : int = randi() % buffStats.size()
	if weapon.buffs.has(roll) and weapon.buffs[roll].stat != buffStats[index]:
		weapon.remove_buff(roll)
	var scene : PackedScene = buffScene
	if index < buffScenes.size():
		scene = buffScenes[index]
	weapon.add_buff(roll, buffStats[index], duration, maxStacks, scene)
