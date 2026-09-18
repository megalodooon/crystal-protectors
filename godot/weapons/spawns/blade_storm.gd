extends Node2D
class_name BladeStormClass


const HIT_SPARK_SCENE := preload("res://vfx/effects/hit_spark.tscn")

@export var radius : float = 20.0
@export var tickInterval : float = 0.3
@export var spinSpeed : float = 10.0
@export var bladeCount : int = 3
@export var fadeTime : float = 0.25
@export var bladeLength : float = 6.0

@onready var detector : Area2D = $Detector
@onready var detectorShape : CollisionShape2D = $Detector/CollisionShape2D
@onready var trails : Array[CPUParticles2D] = [$Trail1, $Trail2, $Trail3]
@onready var glow : Sprite2D = $Glow

var duration : float = 2.5
var damage : float = 10.0
var damageType : DamageTypeClass
var critChance : float = 0.0
var critMultiplier : float = 2.0
var color : Color = Color.WHITE
var age : float = 0.0
var tickTimer : float = 0.0
var spin : float = 0.0

#------------------------#

func _ready() -> void:
	var shape : CircleShape2D = detectorShape.shape
	shape.radius = radius + 5.0
	glow.self_modulate = color
	for trail in trails:
		trail.color = color

func _process(delta : float) -> void:
	age += delta
	spin += spinSpeed * delta
	var fadeIn : float = clampf(age / fadeTime, 0.0, 1.0)
	var fadeOut : float = clampf((duration - age) / fadeTime, 0.0, 1.0)
	modulate.a = minf(fadeIn, fadeOut)
	for i in trails.size():
		trails[i].position = Vector2.from_angle(spin + TAU * i / bladeCount) * radius
		trails[i].emitting = i < bladeCount and age < duration
	if age >= duration + 0.4:
		queue_free()
	queue_redraw()

func _physics_process(delta : float) -> void:
	if age >= duration:
		return
	tickTimer += delta
	if tickTimer < tickInterval:
		return
	tickTimer -= tickInterval
	for area in detector.get_overlapping_areas():
		var hurtbox : HurtboxComponentClass = area as HurtboxComponentClass
		if hurtbox:
			hit(hurtbox)

func hit(hurtbox : HurtboxComponentClass) -> void:
	var isCrit : bool = randf() < critChance
	var hitDamage : float = damage
	if isCrit:
		hitDamage *= critMultiplier
	hurtbox.take_damage(hitDamage, damageType, isCrit)
	var hitSpark : HitSparkClass = HIT_SPARK_SCENE.instantiate()
	hitSpark.position = hurtbox.global_position
	hitSpark.color = color
	hitSpark.strength = 0.7
	hitSpark.sparkAmount = 5
	hitSpark.angle = global_position.angle_to_point(hurtbox.global_position) + PI / 2.0
	get_tree().current_scene.add_child(hitSpark)

func refresh(newDuration : float) -> void:
	duration = maxf(duration, age + newDuration)

func _draw() -> void:
	for i in bladeCount:
		var angle : float = spin + TAU * i / bladeCount
		var center : Vector2 = Vector2.from_angle(angle) * radius
		var tangent : Vector2 = Vector2.from_angle(angle + PI / 2.0)
		var outward : Vector2 = Vector2.from_angle(angle)
		draw_colored_polygon(get_blade(center, tangent, outward, bladeLength, 2.2), Color(color.lerp(Color.WHITE, 0.15), 0.9))
		draw_colored_polygon(get_blade(center, tangent, outward, bladeLength * 0.7, 0.8), Color(1.0, 1.0, 1.0, 0.95))

func get_blade(center : Vector2, tangent : Vector2, outward : Vector2, length : float, thickness : float) -> PackedVector2Array:
	return PackedVector2Array([
		center + tangent * length,
		center + outward * thickness,
		center - tangent * length * 0.45,
		center - outward * thickness * 0.6,
	])
