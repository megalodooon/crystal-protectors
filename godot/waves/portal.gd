extends Node2D
class_name PortalClass


enum State { CLOSED, WARNING, OPEN }

@export var color : Color = Color(0.62, 0.3, 1.0)
@export var voidColor : Color = Color(0.05, 0.0, 0.12)
@export var tinted : Array[CanvasItem]
@export var openTime : float = 0.45
@export var closeTime : float = 0.35
@export var closeDelay : float = 0.8
@export var warningSize : Vector2 = Vector2(0.14, 0.75)
@export_range(0.0, 1.0) var warningIntensity : float = 0.75
@export var spawnSpread : float = 2.5
@export var emergeTime : float = 0.35
@export var emergeColor : Color = Color(2.2, 1.8, 2.6)

@onready var body : Sprite2D = $Body
@onready var groundGlow : Sprite2D = $GroundGlow
@onready var openLoop : Node2D = $OpenLoop
@onready var warningLoop : Node2D = $WarningLoop
@onready var openBurst : Node2D = $OpenBurst
@onready var spawnBurst : Node2D = $SpawnBurst
@onready var closeBurst : Node2D = $CloseBurst

var path : EnemyPathClass
var state : State = State.CLOSED
var isWarning : bool = false
var isClosing : bool = false
var users : int = 0
var closeId : int = 0
var size : Vector2 = Vector2.ZERO
var intensity : float = 0.0
var flash : float = 0.0
var elapsed : float = 0.0
var bodyScale : Vector2
var glowScale : Vector2
var glowAlpha : float
var shader : ShaderMaterial
var tween : Tween

#------------------------#

func _ready() -> void:
	path = get_parent() as EnemyPathClass
	if path and path.curve and path.curve.point_count > 0:
		position = path.curve.get_point_position(0)
	bodyScale = body.scale
	glowScale = groundGlow.scale
	glowAlpha = groundGlow.modulate.a
	shader = body.material
	shader.set_shader_parameter("glowColor", color)
	shader.set_shader_parameter("coreColor", color.lerp(Color.WHITE, 0.55))
	shader.set_shader_parameter("voidColor", voidColor)
	for node in tinted:
		node.modulate = Color(color, node.modulate.a)
	update_state()
	update_visuals()

func _process(delta : float) -> void:
	elapsed += delta
	flash = move_toward(flash, 0.0, delta * 4.0)
	update_visuals()

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
	play_burst(spawnBurst)
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
	if tween:
		tween.kill()
	tween = create_tween().set_parallel()
	match state:
		State.OPEN:
			tween.tween_property(self, "size", Vector2.ONE, openTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "intensity", 1.0, openTime * 0.5)
			flash = 1.0
			play_burst(openBurst)
		State.WARNING:
			tween.tween_property(self, "size", warningSize, closeTime).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "intensity", warningIntensity, closeTime)
		State.CLOSED:
			tween.tween_property(self, "size", Vector2.ZERO, closeTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(self, "intensity", 0.0, closeTime)
	if wasOpen:
		play_burst(closeBurst)
	set_emitting(openLoop, state == State.OPEN)
	set_emitting(warningLoop, state == State.WARNING)

func update_visuals() -> void:
	visible = size.y > 0.001 and intensity > 0.001 and Vfx.is_on_screen(global_position)
	if not visible:
		return
	var flicker : float = 1.0
	if state == State.WARNING:
		flicker = 0.8 + 0.2 * sin(elapsed * 13.0) * sin(elapsed * 4.7)
	body.scale = bodyScale * size * (1.0 + flash * 0.12)
	groundGlow.scale = glowScale * Vector2(lerpf(0.5, 1.0, size.x), 1.0) * (1.0 + flash * 0.2)
	groundGlow.modulate.a = glowAlpha * intensity * flicker
	shader.set_shader_parameter("intensity", intensity * flicker)
	shader.set_shader_parameter("flash", flash)

func set_emitting(group : Node2D, value : bool) -> void:
	for child in group.get_children():
		if child is CPUParticles2D:
			child.emitting = value

func play_burst(group : Node2D) -> void:
	for child in group.get_children():
		if child is CPUParticles2D:
			child.restart()
