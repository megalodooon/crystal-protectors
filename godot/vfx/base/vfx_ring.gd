extends Node2D
class_name VfxRingClass


@export var startRadius : float = 3.0
@export var endRadius : float = 20.0
@export var width : float = 2.5
@export var duration : float = 0.35
@export var delay : float = 0.0
@export var color : Color = Color.WHITE
@export var dashes : int = 0
@export var spin : float = 0.0
@export var easePower : float = 3.0
@export var loop : bool = false

var elapsed : float = 0.0

#------------------------#

func _process(delta : float) -> void:
	elapsed += delta
	if loop and elapsed > delay + duration:
		elapsed -= duration
	queue_redraw()

func _draw() -> void:
	var progress : float = (elapsed - delay) / duration
	if progress < 0.0 or progress > 1.0:
		return
	var grow : float = 1.0 - pow(1.0 - progress, easePower)
	var radius : float = lerpf(startRadius, endRadius, grow)
	var fade : float = 1.0 - progress * progress
	var ringWidth : float = width * (1.0 - progress * 0.6)
	draw_ring(radius, ringWidth * 3.5, Color(color, fade * 0.16))
	draw_ring(radius, ringWidth * 1.8, Color(color, fade * 0.4))
	draw_ring(radius, ringWidth, Color(color.lerp(Color.WHITE, 0.35), fade))
	draw_ring(radius, ringWidth * 0.35, Color(1.0, 1.0, 1.0, fade))

func draw_ring(radius : float, ringWidth : float, ringColor : Color) -> void:
	if radius <= 0.0 or ringWidth <= 0.05:
		return
	if dashes <= 0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ringColor, ringWidth, true)
		return
	var step : float = TAU / dashes
	for i in dashes:
		var start : float = spin * elapsed + step * i
		draw_arc(Vector2.ZERO, radius, start, start + step * 0.55, 8, ringColor, ringWidth, true)
