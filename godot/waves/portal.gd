extends Node2D
class_name PortalClass


enum State { CLOSED, WARNING, OPEN }
enum Row { WARNING, OPEN, OPEN_BURST, SPAWN_BURST, CLOSE_BURST }

@export var frameCounts : PackedInt32Array = PackedInt32Array([30, 30, 12, 12, 9])
@export var fps : float = 15.0
@export var openTime : float = 0.45
@export var closeTime : float = 0.35
@export var closeDelay : float = 0.8
@export var openStartScale : float = 0.25
@export var spawnSpread : float = 2.5
@export var emergeTime : float = 0.35
@export var emergeColor : Color = Color(2.2, 1.8, 2.6)

@onready var body : Sprite2D = $Body
@onready var burst : Sprite2D = $Burst

var path : EnemyPathClass
var state : State = State.CLOSED
var isWarning : bool = false
var isClosing : bool = false
var users : int = 0
var closeId : int = 0
var openScale : float = 0.0
var flash : float = 0.0
var bodyTime : float = 0.0
var burstTime : float = -1.0
var tween : Tween

#------------------------#

func _ready() -> void:
	path = get_parent() as EnemyPathClass
	if path and path.curve and path.curve.point_count > 0:
		position = path.curve.get_point_position(0)
	burst.visible = false
	update_state()
	update_visuals(0.0)

func _process(delta : float) -> void:
	flash = move_toward(flash, 0.0, delta * 4.0)
	update_visuals(delta)

func open() -> void:
	users += 1
	closeId += 1
	isClosing = false
	update_state()

func release() -> void:
	users = maxi(users - 1, 0)
	if users > 0:
		return
	closeId += 1
	var id : int = closeId
	isClosing = true
	await get_tree().create_timer(closeDelay).timeout
	if id == closeId:
		isClosing = false
		update_state()

func set_warning(value : bool) -> void:
	isWarning = value
	if is_node_ready():
		update_state()

func spawn(enemy : EnemyClass) -> void:
	enemy.global_position += Vector2.from_angle(randf() * TAU) * randf() * spawnSpread
	enemy.reset_physics_interpolation()
	flash = 1.0
	play_burst(Row.SPAWN_BURST)
	enemy.visuals.scale.y = 0.0
	enemy.modulate = emergeColor
	var emerge : Tween = enemy.create_tween().set_parallel()
	emerge.tween_property(enemy.visuals, "scale:y", 1.0, emergeTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	emerge.tween_property(enemy, "modulate", Color.WHITE, emergeTime * 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func update_state() -> void:
	var newState : State = State.CLOSED
	if users > 0 or isClosing:
		newState = State.OPEN
	elif isWarning:
		newState = State.WARNING
	if newState == state:
		return
	var wasOpen : bool = state == State.OPEN
	state = newState
	visible = true
	bodyTime = 0.0
	if tween:
		tween.kill()
	tween = create_tween()
	match state:
		State.OPEN:
			openScale = openStartScale
			flash = 1.0
			tween.tween_property(self, "openScale", 1.0, openTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			play_burst(Row.OPEN_BURST)
		State.WARNING:
			tween.tween_property(self, "openScale", 1.0, closeTime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		State.CLOSED:
			tween.tween_property(self, "openScale", 0.0, closeTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if wasOpen:
		play_burst(Row.CLOSE_BURST)

func play_burst(row : Row) -> void:
	burst.frame = get_frame(row, 0)
	burst.visible = true
	burstTime = 0.0

func update_visuals(delta : float) -> void:
	visible = openScale > 0.001 and Vfx.is_on_screen(global_position)
	if not visible:
		return
	bodyTime += delta
	var row : Row = Row.OPEN if state == State.OPEN else Row.WARNING
	body.frame = get_frame(row, int(bodyTime * fps) % frameCounts[row])
	body.scale = Vector2.ONE * openScale * (1.0 + flash * 0.12)
	body.self_modulate = Color(1.0 + flash * 0.5, 1.0 + flash * 0.5, 1.0 + flash * 0.5, minf(openScale * 1.6, 1.0))
	update_burst(delta)

func update_burst(delta : float) -> void:
	if burstTime < 0.0:
		return
	burstTime += delta
	var row : int = burst.frame / body.hframes
	var index : int = int(burstTime * fps)
	if index >= frameCounts[row]:
		burst.visible = false
		burstTime = -1.0
		return
	burst.frame = get_frame(row, index)

func get_frame(row : int, index : int) -> int:
	return row * body.hframes + index
