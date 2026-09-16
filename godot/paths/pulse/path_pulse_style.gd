extends Resource
class_name PathPulseStyleClass


@export var color : Color = Color(0.62, 0.3, 1.0)
@export var coreColor : Color = Color(0.9, 0.78, 1.0)
@export var lineWidth : float = 1.0
@export var glowWidth : float = 3.5
@export_range(0.0, 2.0) var glowStrength : float = 0.8
@export_range(0.0, 3.0) var headGlow : float = 1.5
@export var headLength : float = 12.0
@export var headSize : float = 26.0
@export var trailLength : float = 60.0
@export_range(0.0, 1.0) var afterglow : float = 0.3
@export var speed : float = 120.0
@export var holdTime : float = 0.8
@export var fadeTime : float = 0.6
@export var pauseTime : float = 0.25
@export var stopFadeTime : float = 0.35
@export_range(0.0, 1.0) var waveOpacity : float = 0.4
@export var dotPopTime : float = 0.3
@export var dotRingTime : float = 0.5

#------------------------#
