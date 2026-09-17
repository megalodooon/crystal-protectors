extends HitboxComponentClass
class_name ProjectileClass


@export var speed : float = 150.0
@export var lifetime : float = 2.0

var color : Color = Color.WHITE

#------------------------#

func _ready() -> void:
	super()
	hit.connect(on_hit)
	body_entered.connect(on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta : float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta

func on_hit(_hurtbox : HurtboxComponentClass, _damage : float) -> void:
	if maxHits > 0 and hitCount >= maxHits:
		queue_free()

func on_body_entered(_body : Node2D) -> void:
	queue_free()
