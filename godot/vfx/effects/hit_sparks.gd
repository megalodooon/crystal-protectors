extends Node2D
class_name HitSparksClass


@export var duration : float = 0.25
@export var spikeLength : float = 6.0
@export var spikeWidth : float = 1.2
@export var flashTexture : Texture2D
@export var flashAlpha : float = 0.5
@export var maxParticles : int = 300
@export var maxHits : int = 48

@export_group("Sparks")
@export var sparkTexture : Texture2D
@export var sparkLifetime : float = 0.3
@export var sparkSpeed : Vector2 = Vector2(35.0, 80.0)
@export var sparkDamping : Vector2 = Vector2(250.0, 350.0)
@export var sparkScale : Vector2 = Vector2(0.45, 0.75)
@export var sparkScaleCurve : Curve
@export var sparkColorRamp : Gradient

var hitPositions : PackedVector2Array = []
var hitColors : PackedColorArray = []
var hitStrengths : PackedFloat32Array = []
var hitAges : PackedFloat32Array = []
var hitSpikes : Array[PackedVector3Array] = []

var positions : PackedVector2Array = []
var velocities : PackedVector2Array = []
var times : PackedFloat32Array = []
var dampings : PackedFloat32Array = []
var scales : PackedFloat32Array = []
var colors : PackedColorArray = []

var flashes : MultiMesh
var spikeFronts : MultiMesh
var spikeBacks : MultiMesh
var sparks : MultiMesh

#------------------------#

func _ready() -> void:
	set_process(false)
	var quad : ArrayMesh = make_mesh([Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)], [0, 1, 2, 0, 2, 3])
	flashes = make_multimesh(quad, maxHits)
	sparks = make_multimesh(quad, maxParticles)
	spikeFronts = make_multimesh(make_mesh([Vector2(0.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, -1.0)], [0, 1, 2]), maxHits * 16)
	spikeBacks = make_multimesh(make_mesh([Vector2(0.0, 1.0), Vector2(0.0, -1.0), Vector2(-1.0, 0.0)], [0, 1, 2]), maxHits * 16)

func _process(delta : float) -> void:
	update_hits(delta)
	update_particles(delta)
	if hitAges.is_empty() and times.is_empty():
		set_process(false)
	queue_redraw()

func _draw() -> void:
	draw_flashes()
	draw_spikes()
	draw_sparks()

func add(spot : Vector2, color : Color, strength : float, sparkAmount : int, angle : float) -> void:
	if hitAges.size() >= maxHits:
		return
	var spikes : PackedVector3Array = [Vector3(angle, 1.6, 1.0), Vector3(angle + PI, 1.6, 1.0)]
	for i in randi_range(3, 5):
		spikes.append(Vector3(randf() * TAU, randf_range(0.35, 0.9), randf_range(0.5, 0.9)))
	hitPositions.append(spot)
	hitColors.append(color)
	hitStrengths.append(strength)
	hitAges.append(0.0)
	hitSpikes.append(spikes)
	for i in mini(maxi(sparkAmount, 1), maxParticles - times.size()):
		var direction : Vector2 = Vector2.from_angle(randf_range(-PI, PI))
		positions.append(spot)
		velocities.append(direction * randf_range(sparkSpeed.x, sparkSpeed.y) * strength)
		times.append(0.0)
		dampings.append(randf_range(sparkDamping.x, sparkDamping.y))
		scales.append(randf_range(sparkScale.x, sparkScale.y))
		colors.append(color)
	set_process(true)

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
		times[i] += delta
		if times[i] > sparkLifetime:
			continue
		var velocity : Vector2 = velocities[i]
		var speed : float = velocity.length() - dampings[i] * delta
		if speed > 0.0:
			velocity = velocity.normalized() * speed
		else:
			velocity = velocity.normalized() * 0.001
		velocities[write] = velocity
		positions[write] = positions[i] + velocity * delta
		times[write] = times[i]
		dampings[write] = dampings[i]
		scales[write] = scales[i]
		colors[write] = colors[i]
		write += 1
	if write < count:
		positions.resize(write)
		velocities.resize(write)
		times.resize(write)
		dampings.resize(write)
		scales.resize(write)
		colors.resize(write)

func make_mesh(vertices : PackedVector2Array, indices : PackedInt32Array) -> ArrayMesh:
	var uvs : PackedVector2Array = []
	for vertex in vertices:
		uvs.append(vertex + Vector2(0.5, 0.5))
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh : ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func make_multimesh(mesh : Mesh, count : int) -> MultiMesh:
	var multimesh : MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = count
	multimesh.visible_instance_count = 0
	return multimesh

func draw_flashes() -> void:
	if not flashTexture:
		return
	var textureSize : Vector2 = flashTexture.get_size()
	for h in hitAges.size():
		var progress : float = minf(hitAges[h] / duration, 1.0)
		var size : Vector2 = textureSize * (0.4 + progress * 0.6) * hitStrengths[h]
		flashes.set_instance_transform_2d(h, Transform2D(0.0, size, 0.0, hitPositions[h]))
		flashes.set_instance_color(h, Color(hitColors[h], (1.0 - progress) * flashAlpha))
	flashes.visible_instance_count = hitAges.size()
	draw_multimesh(flashes, flashTexture)

func draw_spikes() -> void:
	var count : int = 0
	for h in hitAges.size():
		var progress : float = minf(hitAges[h] / duration, 1.0)
		var fade : float = 1.0 - progress
		var grow : float = 1.0 - pow(1.0 - minf(progress * 4.0, 1.0), 3.0)
		var strength : float = hitStrengths[h]
		for layer in 2:
			var widthScale : float = 2.0 if layer == 0 else 0.7
			var color : Color = Color(hitColors[h], fade * 0.9) if layer == 0 else Color(1.0, 1.0, 1.0, fade)
			for spike in hitSpikes[h]:
				var length : float = spikeLength * spike.y * grow * strength
				var width : float = spikeWidth * spike.z * widthScale * fade * strength
				if length < 0.2 or width < 0.05 or count >= spikeFronts.instance_count:
					continue
				var direction : Vector2 = Vector2.from_angle(spike.x)
				var side : Vector2 = direction.orthogonal() * width
				spikeFronts.set_instance_transform_2d(count, Transform2D(direction * length, side, hitPositions[h]))
				spikeBacks.set_instance_transform_2d(count, Transform2D(direction * width * 2.0, side, hitPositions[h]))
				spikeFronts.set_instance_color(count, color)
				spikeBacks.set_instance_color(count, color)
				count += 1
	spikeFronts.visible_instance_count = count
	spikeBacks.visible_instance_count = count
	draw_multimesh(spikeFronts, null)
	draw_multimesh(spikeBacks, null)

func draw_sparks() -> void:
	if not sparkTexture:
		return
	var textureSize : Vector2 = sparkTexture.get_size()
	for i in times.size():
		var progress : float = times[i] / sparkLifetime
		var size : float = scales[i]
		if sparkScaleCurve:
			size *= sparkScaleCurve.sample(progress)
		var axis : Vector2 = velocities[i].normalized()
		var color : Color = colors[i]
		if sparkColorRamp:
			color *= sparkColorRamp.sample(progress)
		sparks.set_instance_transform_2d(i, Transform2D(axis.orthogonal() * textureSize.x * size, axis * textureSize.y * size, positions[i]))
		sparks.set_instance_color(i, color)
	sparks.visible_instance_count = times.size()
	draw_multimesh(sparks, sparkTexture)