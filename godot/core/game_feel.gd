extends Node


const HIT_STOP_COOLDOWN : int = 250

var shakeStrength : float = 0.0
var hitStopEndTime : int = -100000

#------------------------#

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta : float) -> void:
	if Engine.time_scale == 0.0 and Time.get_ticks_msec() >= hitStopEndTime:
		Engine.time_scale = 1.0
	update_shake(delta)

func hit_stop(duration : float) -> void:
	if duration <= 0.0:
		return
	var now : int = Time.get_ticks_msec()
	if Engine.time_scale != 0.0 and now < hitStopEndTime + HIT_STOP_COOLDOWN:
		return
	hitStopEndTime = maxi(hitStopEndTime, now + int(duration * 1000.0))
	Engine.time_scale = 0.0

func shake(strength : float) -> void:
	shakeStrength = maxf(shakeStrength, strength)

func update_shake(delta : float) -> void:
	var camera : Camera2D = get_viewport().get_camera_2d()
	if not camera or (shakeStrength == 0.0 and camera.offset == Vector2.ZERO):
		return
	shakeStrength = lerpf(shakeStrength, 0.0, 1.0 - exp(-12.0 * delta))
	if shakeStrength < 0.05:
		shakeStrength = 0.0
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shakeStrength
