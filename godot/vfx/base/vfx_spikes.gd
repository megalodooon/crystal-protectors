extends Node2D
class_name VfxSpikesClass


const QUAD_INDICES : PackedInt32Array = [0, 1, 2, 0, 2, 3]

@export var count : int = 8
@export var length : float = 14.0
@export var width : float = 1.5
@export var duration : float = 0.25
@export var delay : float = 0.0
@export var color : Color = Color.WHITE
@export var randomAngles : bool = true
@export_range(-180.0, 180.0, 1.0, "suffix:°") var angleOffset : float = 0.0
@export var lengthRandomness : float = 0.5
@export var alternate : float = 1.0
@export var spin : float = 0.0

var elapsed : float = 0.0
var spikes : Array[Vector3] = []
var meshPoints : PackedVector2Array = []
var meshColors : PackedColorArray = []
var meshIndices : PackedInt32Array = []

#------------------------#

func _ready() -> void:
	build_spikes()

func restart() -> void:
	elapsed = 0.0
	build_spikes()
	queue_redraw()

func build_spikes() -> void:
	spikes.clear()
	for i in count:
		var angle : float = deg_to_rad(angleOffset) + TAU * i / maxi(count, 1)
		if randomAngles:
			angle += randf_range(-0.3, 0.3) * TAU / maxi(count, 1)
		var spikeLength : float = randf_range(1.0 - lengthRandomness, 1.0)
		if i % 2 == 1:
			spikeLength *= alternate
		spikes.append(Vector3(angle, spikeLength, randf_range(0.7, 1.0)))

func _process(delta : float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var progress : float = (elapsed - delay) / duration
	if progress < 0.0 or progress > 1.0:
		return
	var grow : float = 1.0 - pow(1.0 - minf(progress * 3.0, 1.0), 3.0)
	var fade : float = 1.0 - progress
	meshPoints.clear()
	meshColors.clear()
	meshIndices.clear()
	for spike in spikes:
		add_spike(spike, grow, fade, Color(color, fade * 0.9), 2.2)
	for spike in spikes:
		add_spike(spike, grow, fade, Color(1.0, 1.0, 1.0, fade), 0.8)
	LightningClass.draw_bolt_mesh(self, meshPoints, meshColors, meshIndices)

func add_spike(spike : Vector3, grow : float, fade : float, spikeColor : Color, widthScale : float) -> void:
	var direction : Vector2 = Vector2.from_angle(spike.x + spin * elapsed)
	var spikeLength : float = length * spike.y * grow
	var spikeWidth : float = width * spike.z * widthScale * (0.3 + fade * 0.7)
	if spikeLength < 0.2 or spikeWidth < 0.05:
		return
	var side : Vector2 = direction.orthogonal() * spikeWidth
	var first : int = meshPoints.size()
	meshPoints.push_back(side)
	meshPoints.push_back(direction * spikeLength)
	meshPoints.push_back(-side)
	meshPoints.push_back(-direction * spikeWidth * 1.5)
	for i in 4:
		meshColors.push_back(spikeColor)
	for offset in QUAD_INDICES:
		meshIndices.push_back(first + offset)
