extends Path2D
class_name EnemyPathClass


signal active_changed

@export var active : bool = true : set = set_active
@export var branchFrom : EnemyPathClass
@export var mergeInto : EnemyPathClass
@export var cornerRadius : float = 8.0

var route : Curve2D
var branches : Array[EnemyPathClass]
var branchDistance : float = 0.0
var mergeDistance : float = 0.0
var pulse : PathPulseClass

#------------------------#

func _ready() -> void:
	build_route()

func set_active(value : bool) -> void:
	if active == value:
		return
	active = value
	active_changed.emit()

func build_route() -> void:
	route = Curve2D.new()
	route.bake_interval = 2.0
	if not curve:
		return
	var points : PackedVector2Array = curve.tessellate()
	for i in points.size():
		if i == 0 or i == points.size() - 1:
			route.add_point(points[i])
		else:
			add_corner(points[i - 1], points[i], points[i + 1])

func add_corner(previous : Vector2, corner : Vector2, next : Vector2) -> void:
	var inDirection : Vector2 = previous.direction_to(corner)
	var outDirection : Vector2 = corner.direction_to(next)
	var turn : float = absf(inDirection.angle_to(outDirection))
	var cut : float = minf(cornerRadius * tan(turn / 2.0), minf(previous.distance_to(corner), corner.distance_to(next)) / 2.0)
	if turn < 0.05 or cut < 0.5:
		route.add_point(corner)
		return
	var cornerStart : Vector2 = corner - inDirection * cut
	var cornerEnd : Vector2 = corner + outDirection * cut
	route.add_point(cornerStart, Vector2.ZERO, (corner - cornerStart) * 0.55)
	route.add_point(cornerEnd, (corner - cornerEnd) * 0.55)

func connect_paths() -> void:
	if route.point_count < 2:
		return
	if branchFrom:
		branchDistance = branchFrom.get_closest_distance(get_global_point(0.0))
		branchFrom.branches.append(self)
		route.set_point_position(0, to_local(branchFrom.get_global_point(branchDistance)))
	if mergeInto:
		mergeDistance = mergeInto.get_closest_distance(get_global_point(get_length()))
		route.set_point_position(route.point_count - 1, to_local(mergeInto.get_global_point(mergeDistance)))

func is_fed() -> bool:
	return branchFrom != null and branchFrom.active

func can_merge() -> bool:
	return mergeInto != null and mergeInto.active

func get_length() -> float:
	return route.get_baked_length()

func get_global_point(distance : float) -> Vector2:
	return to_global(route.sample_baked(distance))

func get_closest_distance(globalPoint : Vector2) -> float:
	return route.get_closest_offset(to_local(globalPoint))
