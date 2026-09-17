extends WeaponEffectClass
class_name StatusOnHitEffectClass


@export var status : StatusEffectClass
@export var auraScene : PackedScene
@export var scaleWithPower : bool = true
@export_range(0.0, 1.0) var chance : float = 1.0

#------------------------#

func uses_stat(stat : AttributeClass.Stat) -> bool:
	if stat == AttributeClass.Stat.STATUS_DAMAGE:
		return scaleWithPower
	if stat == AttributeClass.Stat.EFFECT_CHANCE:
		return chance < 1.0
	return stat == AttributeClass.Stat.STATUS_DURATION

func on_equip(weapon : WeaponClass) -> void:
	var sprite : Sprite2D = weapon.get_sprite()
	if not auraScene or not sprite:
		return
	var aura : WeaponAuraClass = auraScene.instantiate()
	aura.texture = sprite.texture
	aura.points = WeaponClass.get_pixel_points(sprite.texture, true)
	sprite.add_child(aura)

func on_hit(weapon : WeaponClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not status or not weapon.roll_chance(chance):
		return
	var newStatus : StatusEffectClass = status.duplicate()
	if scaleWithPower:
		newStatus.scale_power(weapon.get_status_power())
	weapon.add_hit_status(newStatus)
