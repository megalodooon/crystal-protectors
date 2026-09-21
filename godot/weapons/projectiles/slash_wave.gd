extends ProjectileClass
class_name SlashWaveClass


const SEGMENTS : int = 10

@export var radius : float = 5.0
@export var thickness : float = 2.6
@export_range(10.0, 90.0, 1.0, "suffix:°") var halfArc : float = 70.0
@export var fadeTime : float = 0.12

@onready var glow : Sprite2D = $Glow
@onready var trail : VfxTrailClass = $Trail

var age : float = 0.0

#------------------------#

func _ready() -> void:
	super()
	glow.self_modulate = color
	trail.color = Color(color, trail.color.a)
	Vfx.add_cullable(self)

func _process(delta : float) -> void:
	age += delta
	modulate.a = clampf((lifetime - age) / fadeTime, 0.0, 1.0)

func _draw() -> void:
	draw_colored_polygon(get_crescent(halfArc, thickness), color.lerp(Color.WHITE, 0.1))
	draw_colored_polygon(get_crescent(halfArc * 0.75, thickness * 0.4), Color(1.0, 1.0, 1.0, 0.6))

func get_crescent(arc : float, width : float) -> PackedVector2Array:
	var points : PackedVector2Array = []
	for i in SEGMENTS + 1:
		points.append(Vector2.from_angle(deg_to_rad(lerpf(-arc, arc, float(i) / SEGMENTS))) * radius)
	for i in range(SEGMENTS - 1, 0, -1):
		var side : float = lerpf(-1.0, 1.0, float(i) / SEGMENTS)
		points.append(Vector2.from_angle(deg_to_rad(arc * side)) * radius - Vector2(width * (1.0 - side * side), 0.0))
	return points

func on_hit(hurtbox : HurtboxComponentClass, hitDamage : float) -> void:
	Vfx.show_hit_spark(hurtbox.global_position, color, 0.6, 3, rotation + PI / 2.0)
	super(hurtbox, hitDamage)
