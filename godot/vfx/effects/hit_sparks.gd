extends Node2D
class_name HitSparksClass


const SPARK : int = 0
const ORB : int = 1

@export var duration : float = 0.25
@export var spikeLength : float = 9.0
@export var spikeWidth : float = 1.2
@export var flashTexture : Texture2D
@export var flashAlpha : float = 0.8
@export var maxParticles : int = 500

@export_group("Sparks")
@export var sparkTexture : Texture2D
@export var sparkLifetime : float = 0.35
@export var sparkSpeed : Vector2 = Vector2(40.0, 100.0)
@export var sparkDamping : Vector2 = Vector2(250.0, 350.0)
@export var sparkScale : Vector2 = Vector2(0.6, 1.0)
@export var sparkScaleCurve : Curve
@export var sparkColorRamp : Gradient

@export_group("Orbs")
@export var orbTexture : Texture2D
@export var orbLifetime : float = 0.7
@export_range(0.0, 1.0) var orbExplosiveness : float = 0.9
@export_range(0.0, 1.0) var orbRandomness : float = 0.5
@export var orbSpeed : Vector2 = Vector2(15.0, 45.0)
@export var orbDamping : Vector2 = Vector2(40.0, 60.0)
@export var orbScale : Vector2 = Vector2(0.5, 1.1)
@export var orbLighten : float = 0.3
@export var orbScaleCurve : Curve
@export var orbColorRamp : Gradient

var hitPositions : PackedVector2Array = []
var hitColors : PackedColorArray = []
var hitStrengths : PackedFloat32Array = []
var hitAges : PackedFloat32Array = []
var hitSpikes : Array[PackedVector3Array] = []

var positions : PackedVector2Array = []
var velocities : PackedVector2Array = []
var axes : PackedVector2Array = []
var times : PackedFloat32Array = []
var lifetimes : PackedFloat32Array = []
var dampings : PackedFloat32Array = []
var scales : PackedFloat32Array = []
var sizes : PackedFloat32Array = []
var colors : PackedColorArray = []
var shownColors : PackedColorArray = []
var kinds : PackedByteArray = []
var emitted : PackedByteArray = []

#------------------------#

func _ready() -> void:
	set_process(false)

func _process(delta : float) -> void:
	update_hits(delta)
	update_particles(delta)
	if hitAges.is_empty() and times.is_empty():
		set_process(false)
	queue_redraw()

func _draw() -> void:
	for h in hitAges.size():
		var progress : float = minf(hitAges[h] / duration, 1.0)
		var fade : float = 1.0 - progress
		var grow : float = 1.0 - pow(1.0 - minf(progress * 4.0, 1.0), 3.0)
		var color : Color = hitColors[h]
		draw_set_transform(hitPositions[h], 0.0, Vector2.ONE * hitStrengths[h])
		for spike in hitSpikes[h]:
			draw_spike(spike, grow, fade, Color(color, fade * 0.9), 2.0)
		for spike in hitSpikes[h]:
			draw_spike(spike, grow, fade, Color(1.0, 1.0, 1.0, fade), 0.7)
		var flashSize : Vector2 = flashTexture.get_size() * (0.4 + progress * 0.6)
		draw_texture_rect(flashTexture, Rect2(-flashSize / 2.0, flashSize), false, Color(color, fade * flashAlpha))
	for i in times.size():
		if not emitted[i]:
			continue
		var size : float = sizes[i]
		if kinds[i] == SPARK:
			draw_set_transform_matrix(Transform2D(axes[i].orthogonal() * size, axes[i] * size, positions[i]))
			draw_texture(sparkTexture, -sparkTexture.get_size() / 2.0, shownColors[i])
		else:
			draw_set_transform(positions[i], 0.0, Vector2.ONE * size)
			draw_texture(orbTexture, -orbTexture.get_size() / 2.0, shownColors[i])
	draw_set_transform_matrix(Transform2D.IDENTITY)

func draw_spike(spike : Vector3, grow : float, fade : float, spikeColor : Color, widthScale : float) -> void:
	var direction : Vector2 = Vector2.from_angle(spike.x)
	var length : float = spikeLength * spike.y * grow
	var width : float = spikeWidth * spike.z * widthScale * fade
	if length < 0.2 or width < 0.05:
		return
	var side : Vector2 = direction.orthogonal() * width
	draw_colored_polygon(PackedVector2Array([side, direction * length, -side, -direction * width * 2.0]), spikeColor)

func add(spot : Vector2, color : Color, strength : float, sparkAmount : int, orbAmount : int, angle : float) -> void:
	var spikes : PackedVector3Array = [Vector3(angle, 1.6, 1.0), Vector3(angle + PI, 1.6, 1.0)]
	for i in randi_range(4, 7):
		spikes.append(Vector3(randf() * TAU, randf_range(0.35, 0.9), randf_range(0.5, 0.9)))
	hitPositions.append(spot)
	hitColors.append(color)
	hitStrengths.append(strength)
	hitAges.append(0.0)
	hitSpikes.append(spikes)
	var room : int = maxParticles - times.size()
	var sparkCount : int = mini(maxi(sparkAmount, 1), room)
	for i in sparkCount:
		add_particle(SPARK, spot, color, strength, sparkSpeed, sparkDamping, sparkScale, sparkLifetime, 0.0)
	var orbCount : int = mini(orbAmount, room - sparkCount)
	var orbColor : Color = color.lightened(orbLighten)
	for i in orbCount:
		var phase : float = (float(i) + orbRandomness * randf()) / orbCount
		add_particle(ORB, spot, orbColor, strength, orbSpeed, orbDamping, orbScale, orbLifetime, phase * (1.0 - orbExplosiveness) * orbLifetime)
	set_process(true)

func add_particle(kind : int, spot : Vector2, color : Color, strength : float, speed : Vector2, damping : Vector2, scaleRange : Vector2, lifetime : float, delay : float) -> void:
	var direction : Vector2 = Vector2.from_angle(randf_range(-PI, PI))
	positions.append(spot)
	velocities.append(direction * randf_range(speed.x, speed.y) * strength)
	axes.append(direction)
	times.append(-delay)
	lifetimes.append(lifetime)
	dampings.append(randf_range(damping.x, damping.y))
	scales.append(randf_range(scaleRange.x, scaleRange.y))
	sizes.append(0.0)
	colors.append(color)
	shownColors.append(Color(color, 0.0))
	kinds.append(kind)
	emitted.append(0)

func update_hits(delta : float) -> void:
	var expired : int = 0
	for h in hitAges.size():
		hitAges[h] += delta
		if hitAges[h] >= duration:
			expired = h + 1
	if expired > 0:
		hitPositions = hitPositions.slice(expired)
		hitColors = hitColors.slice(expired)
		hitStrengths = hitStrengths.slice(expired)
		hitAges = hitAges.slice(expired)
		hitSpikes = hitSpikes.slice(expired)

func update_particles(delta : float) -> void:
	var count : int = times.size()
	var write : int = 0
	for i in count:
		var velocity : Vector2 = velocities[i]
		if emitted[i]:
			if times[i] > lifetimes[i]:
				continue
			times[i] += delta
			var speed : float = velocity.length() - dampings[i] * delta
			velocity = velocity.normalized() * speed if speed > 0.0 else Vector2.ZERO
			velocities[i] = velocity
			positions[i] += velocity * delta
		else:
			times[i] += delta
			if times[i] >= 0.0:
				emitted[i] = 1
				positions[i] += velocity * times[i]
				times[i] = 0.0
		if emitted[i]:
			update_look(i, velocity)
		if write != i:
			copy_particle(i, write)
		write += 1
	if write < count:
		positions.resize(write)
		velocities.resize(write)
		axes.resize(write)
		times.resize(write)
		lifetimes.resize(write)
		dampings.resize(write)
		scales.resize(write)
		sizes.resize(write)
		colors.resize(write)
		shownColors.resize(write)
		kinds.resize(write)
		emitted.resize(write)

func update_look(i : int, velocity : Vector2) -> void:
	var progress : float = times[i] / lifetimes[i]
	var curve : Curve = sparkScaleCurve if kinds[i] == SPARK else orbScaleCurve
	var ramp : Gradient = sparkColorRamp if kinds[i] == SPARK else orbColorRamp
	var baseScale : float = scales[i]
	if curve:
		baseScale *= curve.sample(progress)
	baseScale = maxf(baseScale, 0.00001)
	if kinds[i] == ORB or velocity != Vector2.ZERO:
		sizes[i] = baseScale
		if velocity != Vector2.ZERO:
			axes[i] = velocity.normalized()
	else:
		sizes[i] *= baseScale
	shownColors[i] = ramp.sample(progress) * colors[i] if ramp else colors[i]

func copy_particle(from : int, to : int) -> void:
	positions[to] = positions[from]
	velocities[to] = velocities[from]
	axes[to] = axes[from]
	times[to] = times[from]
	lifetimes[to] = lifetimes[from]
	dampings[to] = dampings[from]
	scales[to] = scales[from]
	sizes[to] = sizes[from]
	colors[to] = colors[from]
	shownColors[to] = shownColors[from]
	kinds[to] = kinds[from]
	emitted[to] = emitted[from]
