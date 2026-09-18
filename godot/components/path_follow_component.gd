extends Node
class_name PathFollowComponentClass


signal reached_end

const STEP : float = 1.0
const MAX_STEPS : int = 64

@export var lookAhead : float = 4.0
@export var arriveDistance : float = 1.0

var path : EnemyPathClass
var distance : float = 0.0
var hasReachedEnd : bool = false

#------------------------#

func start(newPath : EnemyPathClass, body : Node2D) -> void:
	path = newPath
	distance = 0.0
	hasReachedEnd = false
	body.global_position = path.get_global_point(0.0)
	body.reset_physics_interpolation()

func get_direction(body : Node2D) -> Vector2:
	if not path or hasReachedEnd:
		return Vector2.ZERO
	var target : Vector2 = path.get_global_point(distance)
	var steps : int = 0
	while body.global_position.distance_to(target) < lookAhead and not is_at_end() and steps < MAX_STEPS:
		advance(STEP)
		target = path.get_global_point(distance)
		steps += 1
	if is_at_end() and body.global_position.distance_to(target) <= arriveDistance:
		hasReachedEnd = true
		reached_end.emit()
		return Vector2.ZERO
	return body.global_position.direction_to(target)

func is_at_end() -> bool:
	return distance >= path.get_length() and not path.can_merge()

func advance(amount : float) -> void:
	var nextDistance : float = distance + amount
	var choices : Array[EnemyPathClass] = []
	for branch in path.branches:
		if branch.active and branch.branchDistance > distance and branch.branchDistance <= nextDistance:
			choices.append(branch)
	var choice : int = randi_range(0, choices.size())
	if choice < choices.size():
		distance = nextDistance - choices[choice].branchDistance
		path = choices[choice]
		return
	if nextDistance >= path.get_length() and path.can_merge():
		distance = path.mergeDistance + nextDistance - path.get_length()
		path = path.mergeInto
		return
	distance = minf(nextDistance, path.get_length())
