extends StateClass


@export var moveState : StateClass
@export var canMove : bool = true

@onready var player : PlayerClass = owner

#------------------------#

func physics_update(delta : float) -> void:
	var direction : Vector2 = Vector2.ZERO
	if canMove:
		direction = Input.get_vector("left", "right", "up", "down")
	player.movementComponent.move(player, direction, delta)
	if direction != Vector2.ZERO:
		player.animationPlayer.play("walk")
	else:
		player.animationPlayer.play("idle")
	player.weapon.attack()
	if not Input.is_action_pressed("attack"):
		stateMachine.change_state(moveState)
