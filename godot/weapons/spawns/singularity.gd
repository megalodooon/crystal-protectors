extends WeaponSpawnClass
class_name SingularityClass


@export var baseRadius : float = 30.0
@export var pullSpeed : float = 34.0
@export var damageRadius : float = 0.6
@export var collapseScene : PackedScene

@onready var visuals : Node2D = $Visuals

#------------------------#

func _ready() -> void:
	visuals.scale = Vector2.ONE * radius / baseRadius

func _process(delta : float) -> void:
	super(delta)
	visuals.rotation -= delta * 2.5

func _physics_process(delta : float) -> void:
	super(delta)
	if not is_active():
		return
	for hurtbox in get_targets(global_position, radius):
		var toCenter : Vector2 = global_position - hurtbox.global_position
		if toCenter.length() > 2.0:
			hurtbox.displace(toCenter.limit_length(pullSpeed * delta))

func on_tick() -> void:
	for hurtbox in get_targets(global_position, radius * damageRadius):
		hit(hurtbox, damage)

func on_end() -> void:
	super()
	spawn_vfx(collapseScene, global_position, radius)
