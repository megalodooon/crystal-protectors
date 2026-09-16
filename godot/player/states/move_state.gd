extends StateClass


@export var attackState : StateClass

@onready var player : PlayerClass = owner

#------------------------#

func physics_update(delta : float) -> void:
	var direction : Vector2 = Input.get_vector("left", "right", "up", "down")
	player.movementComponent.move(player, direction, delta)
	if direction != Vector2.ZERO:
		player.animationPlayer.play("walk")
	else:
		player.animationPlayer.play("idle")
	if Input.is_action_pressed("attack") and player.weapon:
		stateMachine.change_state(attackState)
