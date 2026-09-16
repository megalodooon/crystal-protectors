extends WeaponEffectClass
class_name StatusOnHitEffectClass


@export var status : StatusEffectClass
@export var auraScene : PackedScene
@export var scaleWithPower : bool = true

#------------------------#

func on_equip(weapon : WeaponClass) -> void:
	var sprite : Sprite2D = weapon.get_sprite()
	if not auraScene or not sprite:
		return
	var aura : WeaponAuraClass = auraScene.instantiate()
	aura.texture = sprite.texture
	aura.points = WeaponClass.get_pixel_points(sprite.texture, true)
	sprite.add_child(aura)

func on_hit(weapon : WeaponClass, _hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not status:
		return
	var newStatus : StatusEffectClass = status.duplicate()
	if scaleWithPower:
		newStatus.scale_power(weapon.get_status_power())
	weapon.add_hit_status(newStatus)
