extends Node2D
class_name PathPulseClass


const MAX_PULSES : int = 8
const STEP : float = 0.5
const BEND_SPAN : float = 2.0

@export var headTexture : Texture2D

@onready var line : MeshInstance2D = $Line
@onready var startDot : PathDotClass = $StartDot
@onready var endDot : PathDotClass = $EndDot

var style : PathPulseStyleClass
var route : Curve2D
var sources : Array[Vector2]
var isSpawn : bool = false
var heads : PackedVector2Array = []
var headCount : int = 0
var length : float = 0.0
var opacity : float = 1.0
var gray : float = 0.0
var shader : ShaderMaterial

#------------------------#

func _draw() -> void:
	if not headTexture or not style:
		return
	var size : Vector2 = Vector2.ONE * style.headSize
	for i in headCount:
		var fade : float = 1.0 - clampf((heads[i].y - length) / style.headLength, 0.0, 1.0)
		if fade > 0.0:
			var color : Color = Color(PathDotClass.get_gray_color(style.color, gray), style.headGlow * 0.5 * fade * opacity)
			draw_texture_rect(headTexture, Rect2(get_point(minf(heads[i].y, length)) - size / 2.0, size), false, color)

func build(path : EnemyPathClass, pulseStyle : PathPulseStyleClass) -> void:
	style = pulseStyle
	route = path.route
	shader = line.material
	length = path.get_length()
	heads.resize(MAX_PULSES)
	var halfWidth : float = style.glowWidth * 3.0
	build_mesh(halfWidth)
	shader.set_shader_parameter("glowColor", style.color)
	shader.set_shader_parameter("coreColor", style.coreColor)
	shader.set_shader_parameter("pathLength", length)
	shader.set_shader_parameter("halfWidth", halfWidth)
	shader.set_shader_parameter("lineWidth", style.lineWidth)
	shader.set_shader_parameter("glowWidth", style.glowWidth)
	shader.set_shader_parameter("glowStrength", style.glowStrength)
	shader.set_shader_parameter("headGlow", style.headGlow)
	shader.set_shader_parameter("headLength", style.headLength)
	shader.set_shader_parameter("trailLength", style.trailLength)
	shader.set_shader_parameter("afterglow", style.afterglow)
	startDot.position = route.sample_baked(0.0)
	endDot.position = route.sample_baked(length)
	startDot.set_colors(style.color, style.coreColor)
	endDot.set_colors(style.color, style.coreColor)
	if path.mergeInto:
		endDot.queue_free()
		endDot = null

func build_mesh(halfWidth : float) -> void:
	if length < BEND_SPAN:
		return
	var steps : int = ceili((length + halfWidth * 2.0) / STEP)
	var distances : PackedFloat32Array = []
	var bends : PackedFloat32Array = []
	for i in steps + 1:
		var distance : float = lerpf(-halfWidth, length + halfWidth, float(i) / steps)
		distances.append(distance)
		bends.append(get_direction(distance - BEND_SPAN).angle_to(get_direction(distance + BEND_SPAN)))
	var window : int = ceili(halfWidth / STEP)
	var vertices : PackedVector2Array = []
	var uvs : PackedVector2Array = []
	var colors : PackedColorArray = []
	for i in distances.size():
		var leftWidth : float = halfWidth
		var rightWidth : float = halfWidth
		for j in range(maxi(i - window, 0), mini(i + window + 1, distances.size())):
			var bendRadius : float = BEND_SPAN * 2.0 / maxf(absf(bends[j]), 0.001) * 0.9
			if bends[j] > 0.0:
				leftWidth = minf(leftWidth, bendRadius)
			else:
				rightWidth = minf(rightWidth, bendRadius)
		var point : Vector2 = get_point(distances[i])
		var normal : Vector2 = get_direction(distances[i]).orthogonal()
		var edges : Color = Color(leftWidth / halfWidth, rightWidth / halfWidth, 1.0)
		vertices.append(point - normal * leftWidth)
		vertices.append(point + normal * rightWidth)
		uvs.append(Vector2(distances[i], 0.5 - leftWidth / halfWidth * 0.5))
		uvs.append(Vector2(distances[i], 0.5 + rightWidth / halfWidth * 0.5))
		colors.append(edges)
		colors.append(edges)
	var arrays : Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh : ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	line.mesh = mesh

func get_point(distance : float) -> Vector2:
	var clamped : float = clampf(distance, 0.0, length)
	return route.sample_baked(clamped, true) + get_direction(clamped) * (distance - clamped)

func get_direction(distance : float) -> Vector2:
	var clamped : float = clampf(distance, 1.0, length - 1.0)
	return route.sample_baked(clamped - 1.0, true).direction_to(route.sample_baked(clamped + 1.0, true))

func update_pulse(time : float, newOpacity : float, newGray : float) -> void:
	opacity = newOpacity
	gray = newGray
	headCount = 0
	var startReachTime : float = INF
	if isSpawn:
		startReachTime = 0.0
	var endReachTime : float = INF
	for source in sources:
		endReachTime = minf(endReachTime, source.y + (length - source.x) / style.speed)
		if time >= source.y:
			heads[headCount] = Vector2(source.x, source.x + (time - source.y) * style.speed)
			headCount += 1
	shader.set_shader_parameter("pulses", heads)
	shader.set_shader_parameter("pulseCount", headCount)
	shader.set_shader_parameter("opacity", opacity)
	shader.set_shader_parameter("gray", gray)
	startDot.update_dot(time - startReachTime, opacity, gray, style)
	if endDot:
		endDot.update_dot(time - endReachTime, opacity, gray, style)
	queue_redraw()
