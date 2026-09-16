extends WeaponEffectClass
class_name FireEffectClass


const FLAMES_SCENE := preload("res://weapons/effects/fire/weapon_flames.tscn")

@export var burn : BurnEffectClass
@export var scaleWithRarity : bool = true

#------------------------#

func on_equip(weapon : WeaponClass) -> void:
	var sprite : Sprite2D = weapon.get_sprite()
	if not sprite:
		return
	var flames : WeaponFlamesClass = FLAMES_SCENE.instantiate()
	flames.texture = sprite.texture
	flames.points = WeaponClass.get_pixel_points(sprite.texture, true)
	sprite.add_child(flames)

func on_hit(weapon : WeaponClass, hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if not burn or not is_instance_valid(hurtbox):
		return
	var newBurn : BurnEffectClass = burn.duplicate()
	if scaleWithRarity and weapon.rarity:
		newBurn.damagePerTick *= weapon.rarity.damageMultiplier
	hurtbox.apply_status(newBurn)
