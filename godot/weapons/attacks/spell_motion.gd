extends Resource
class_name SpellMotionClass


@export var distance : float = 110.0
@export var flightTime : float = 0.55
@export var travelCurve : Curve

@export_group("Formation")
@export var spawnRadius : float = 0.0
@export_range(0.0, 360.0, 1.0, "suffix:°") var spawnArc : float = 0.0
@export_range(-180.0, 180.0, 1.0, "suffix:°") var spawnAngle : float = 180.0
@export var holdTime : float = 0.0
@export var launchStagger : float = 0.0
@export var convergeDistance : float = 0.0

@export_group("Path")
@export var swayAmount : float = 0.0
@export var swayCurve : Curve
@export var waveAmount : float = 0.0
@export var waves : float = 1.0
@export var orbitRadius : float = 0.0
@export var orbitTurns : float = 1.0
@export var orbitCurve : Curve

@export_group("Seeking")
@export var homing : float = 0.0
@export var homingRange : float = 70.0
@export_range(0.0, 1.0) var homingStart : float = 0.0

#------------------------#

func get_travel(progress : float) -> float:
	if travelCurve:
		return travelCurve.sample(progress)
	return 1.0 - (1.0 - progress) * (1.0 - progress)

func get_offset(progress : float, side : float, phase : float) -> Vector2:
	var offset : Vector2 = Vector2.ZERO
	if swayAmount != 0.0:
		var sway : float = swayCurve.sample(progress) if swayCurve else sin(progress * PI)
		offset.y += swayAmount * sway * side
	if waveAmount != 0.0:
		offset.y += waveAmount * sin(progress * waves * TAU + phase) * minf(progress * 5.0, 1.0)
	if orbitRadius != 0.0:
		var radius : float = orbitRadius * (orbitCurve.sample(progress) if orbitCurve else minf(progress * 4.0, 1.0))
		offset += Vector2.from_angle(progress * orbitTurns * TAU + phase) * radius
	return offset

func get_spawn_offset(index : int, count : int) -> Vector2:
	if spawnRadius <= 0.0:
		return Vector2.ZERO
	var angle : float = deg_to_rad(spawnAngle)
	if count > 1:
		angle += deg_to_rad(lerpf(-spawnArc / 2.0, spawnArc / 2.0, float(index) / (count - 1)))
	return Vector2.from_angle(angle) * spawnRadius

func get_hold_time(index : int) -> float:
	return holdTime + launchStagger * index
