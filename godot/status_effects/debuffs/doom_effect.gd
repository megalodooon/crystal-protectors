extends StatusEffectClass
class_name DoomEffectClass


@export var bonus : float = 0.2
@export var damageType : DamageTypeClass
@export var burstScene : PackedScene

var storedDamage : float = 0.0

#------------------------#

func refresh(newEffect : StatusEffectClass) -> void:
	var newDoom : DoomEffectClass = newEffect as DoomEffectClass
	if newDoom:
		bonus = maxf(bonus, newDoom.bonus)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherDoom : DoomEffectClass = other as DoomEffectClass
	if otherDoom:
		bonus = maxf(bonus, otherDoom.bonus)

func set_strength(amount : float) -> void:
	bonus = amount

func on_damage_taken(amount : float, _damageType : DamageTypeClass) -> void:
	storedDamage += amount

func on_remove() -> void:
	var hurtbox : HurtboxComponentClass = status.hurtbox
	if not is_instance_valid(hurtbox):
		return
	Vfx.spawn_effect(burstScene, hurtbox.global_position)
	if storedDamage > 0.0:
		hurtbox.take_damage(storedDamage * bonus, damageType)
