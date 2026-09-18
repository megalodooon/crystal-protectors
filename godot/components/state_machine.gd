extends Node
class_name StateMachineClass


@export var initialState : StateClass

var currentState : StateClass

#------------------------#

func _ready() -> void:
	for child in get_children():
		if child is StateClass:
			child.stateMachine = self
	await owner.ready
	change_state(initialState)

func _physics_process(delta : float) -> void:
	if currentState:
		currentState.physics_update(delta)

func change_state(newState : StateClass) -> void:
	if currentState:
		currentState.exit()
	currentState = newState
	currentState.enter()
