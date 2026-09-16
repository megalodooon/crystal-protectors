extends Node2D
class_name SlashClass

const HIT_SPARK_SCENE := preload("res://vfx/hit_spark/hit_spark.tscn")
const SEGMENTS : int = 40

@onready var arc : MeshInstance2D = $Arc
@onready var hitbox : HitboxComponentClass = $HitboxComponent
@onready var hitboxShape : CollisionPolygon2D = $HitboxComponent/CollisionPolygon2D

var attack : AttackClass
var style : SlashStyleClass
var colors : Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE]
var radius : float = 17.0
var size : float = 14.0
var curve : float = 160.0
var swingDirection : float = 1.0
var elapsed : float = 0.0
var hitFeelPlayed : bool = false
var shader : ShaderMaterial

#------------------------#

func _ready() -> void:
	shader = arc.material
	setup_arc()
	setup_hitbox()
	update_arc(0.0)
	get_tree().create_timer(style.duration + 0.8).timeout.connect(queue_free)

func _process(delta : float) -> void:
	elapsed += delta
	var progress : float = minf(elapsed / style.duration, 1.0)
	update_arc(progress)

func setup_arc() -> void:
	var bandInner : float = maxf(radius - size / 2.0, 0.0)
	var bandOuter : float = radius + size / 2.0
	var padding : float = size * 0.5 + 3.0
	var meshInner : float = maxf(bandInner - padding, 0.0)
	var meshOuter : float = bandOuter + padding
	var halfCurve : float = deg_to_rad(curve) / 2.0
	var vertices : PackedVector2Array = []
	var uvs : PackedVector2Array = []
	for i in SEGMENTS + 1:
		var u : float = float(i) / SEGMENTS
		var direction : Vector2 = Vector2.from_angle(lerpf(-halfCurve, halfCurve, u) * swingDirection)
		vertices.append(direction * meshInner)
		vertices.append(direction * meshOuter)
		uvs.append(Vector2(u, 0.0))
		uvs.append(Vector2(u, 1.0))
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh : ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	arc.mesh = mesh
	shader.set_shader_parameter("darkColor", colors[0])
	shader.set_shader_parameter("mainColor", colors[1])
	shader.set_shader_parameter("lightColor", colors[2])
	shader.set_shader_parameter("meshInner", meshInner)
	shader.set_shader_parameter("meshOuter", meshOuter)
	shader.set_shader_parameter("bandInner", bandInner)
	shader.set_shader_parameter("bandOuter", bandOuter)
	shader.set_shader_parameter("arcLength", deg_to_rad(curve) * bandOuter)
	shader.set_shader_parameter("glow", style.glow)
	shader.set_shader_parameter("core", style.core)
	shader.set_shader_parameter("tipGlow", style.tipGlow)
	shader.set_shader_parameter("streaks", style.streaks)
	shader.set_shader_parameter("chromatic", style.chromaticAberration)

func setup_hitbox() -> void:
	var halfCurve : float = deg_to_rad(minf(curve, 359.0)) / 2.0
	var points : PackedVector2Array = []
	for i in SEGMENTS + 1:
		points.append(Vector2.from_angle(lerpf(-halfCurve, halfCurve, float(i) / SEGMENTS)) * (radius + size / 2.0))
	if curve < 359.0:
		points.append(Vector2.ZERO)
	hitboxShape.polygon = points
	attack.setup_hitbox(hitbox)
	hitbox.hit.connect(on_hit)
	hitbox.set_deferred("monitoring", true)
	get_tree().create_timer(style.duration * 0.6).timeout.connect(end_hitbox)

func end_hitbox() -> void:
	hitbox.set_deferred("monitoring", false)

func update_arc(progress : float) -> void:
	var swing : float = minf(progress / 0.7, 1.0)
	shader.set_shader_parameter("head", 1.0 - pow(1.0 - swing, 3.0))
	shader.set_shader_parameter("trail", style.trail * (1.0 - smoothstep(0.7, 1.0, progress) * 0.6))
	shader.set_shader_parameter("opacity", 1.0 - smoothstep(0.6, 1.0, progress))

func on_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	if is_instance_valid(attack):
		attack.register_hit(hurtbox, hitDamage)
	var hitSpark : HitSparkClass = HIT_SPARK_SCENE.instantiate()
	hitSpark.global_position = hurtbox.global_position
	hitSpark.color = colors[1]
	hitSpark.strength = style.hitSparkSize
	hitSpark.sparkAmount = style.hitSparkAmount
	hitSpark.orbAmount = style.orbAmount
	hitSpark.angle = (hurtbox.global_position - global_position).angle() + PI / 2.0 * swingDirection
	get_tree().current_scene.add_child(hitSpark)
	if not hitFeelPlayed:
		hitFeelPlayed = true
		GameFeel.hit_stop(style.hitStop)
		GameFeel.shake(style.screenShake)
