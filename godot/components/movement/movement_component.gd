extends Node
class_name MovementComponentClass


@export var speed : float = 80.0
@export var acceleration : float = 1000.0
@export var deceleration : float = 1000.0

#------------------------#

func move(body : CharacterBody2D, direction : Vector2, delta : float) -> void:
	if direction != Vector2.ZERO:
		body.velocity = body.velocity.move_toward(direction * speed, acceleration * delta)
	else:
		body.velocity = body.velocity.move_toward(Vector2.ZERO, deceleration * delta)
	body.move_and_slide()
