extends AttackClass
class_name MeleeAttackClass


@export var hitbox : HitboxComponentClass
@export var activeTime : float = 0.15

#------------------------#

func _ready() -> void:
	hitbox.monitoring = false
	hitbox.hit.connect(register_hit)

func perform() -> void:
	setup_hitbox(hitbox)
	hitbox.set_deferred("monitoring", true)
	get_tree().create_timer(activeTime).timeout.connect(end_attack)

func end_attack() -> void:
	hitbox.set_deferred("monitoring", false)
