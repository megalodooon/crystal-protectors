extends WeaponEffectClass
class_name StatusOnHitEffectClass


@export var status : StatusEffectClass
@export var auraScene : PackedScene
@export var scaleWithRarity : bool = true

#------------------------#

func on_equip(weapon : WeaponClass) -> void:
	var sprite : Sprite2D = weapon.get_sprite()
	if not auraScene or not sprite:
		return
	var aura : WeaponAuraClass = auraScene.instantiate()
	aura.texture = sprite.texture
	aura.points = WeaponClass.get_pixel_points(sprite.texture, true)
	sprite.add_child(aura)

func on_hit(weapon : WeaponClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not status or not is_instance_valid(hurtbox):
		return
	var newStatus : StatusEffectClass = status.duplicate()
	if scaleWithRarity and weapon.rarity:
		newStatus.scale_power(weapon.rarity.damageMultiplier)
	hurtbox.apply_status(newStatus)
