extends WeaponSpawnClass
class_name SoulLinkClass


const GLOW_TEXTURE := preload("res://vfx/shared/soft_glow.tres")

@export var maxLinks : int = 4
@export var tetherWidth : float = 0.8
@export var tetherColor : Color = Color(0.45, 0.95, 1.0)
@export var linkScene : PackedScene

var links : Array[HurtboxComponentClass] = []
var healths : Array[float] = []
var sharing : bool = false
var pulse : float = 0.0

#------------------------#

func _ready() -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	links.append(target)
	var others : Array[HurtboxComponentClass] = get_targets(target.global_position, radius)
	others.sort_custom(func(a : HurtboxComponentClass, b : HurtboxComponentClass) -> bool: return target.global_position.distance_squared_to(a.global_position) < target.global_position.distance_squared_to(b.global_position))
	for other in others:
		if links.size() >= maxLinks:
			break
		if not links.has(other) and not other.is_dead():
			links.append(other)
	if links.size() < 2:
		queue_free()
		return
	for link in links:
		healths.append(link.healthComponent.currentHealth)
		link.healthComponent.health_changed.connect(on_health_changed.bind(link))
		spawn_vfx(linkScene, link.global_position)

func _process(delta : float) -> void:
	super(delta)
	pulse = move_toward(pulse, 0.0, delta * 4.0)
	queue_redraw()

func on_health_changed(currentHealth : float, _maxHealth : float, link : HurtboxComponentClass) -> void:
	var index : int = links.find(link)
	var lost : float = healths[index] - currentHealth
	healths[index] = currentHealth
	if lost <= 0.0 or sharing or not is_active():
		return
	sharing = true
	for other in links:
		if other != link and is_instance_valid(other) and not other.is_dead():
			other.take_damage(lost * value, damageType)
	sharing = false
	pulse = 1.0

func _draw() -> void:
	var alive : Array[Vector2] = []
	for link in links:
		if is_instance_valid(link) and not link.is_dead():
			alive.append(to_local(link.global_position))
	if alive.size() < 2:
		return
	var glowColor : Color = tetherColor.lerp(Color.WHITE, pulse * 0.4)
	var meshPoints : PackedVector2Array = []
	var meshColors : PackedColorArray = []
	var meshIndices : PackedInt32Array = []
	for i in alive.size():
		var glowSize : float = 18.0 + pulse * 8.0
		draw_texture_rect(GLOW_TEXTURE, Rect2(alive[i] - Vector2.ONE * glowSize / 2.0, Vector2.ONE * glowSize), false, Color(glowColor, 0.35 + pulse * 0.3))
		if i == 0:
			continue
		var tether : PackedVector2Array = get_tether(alive[0], alive[i], i)
		LightningClass.add_layers(meshPoints, meshColors, meshIndices, tether, tetherWidth * (1.0 + pulse * 0.6), glowColor, 0.75 + pulse * 0.25)
		for j in 2:
			var travel : float = fmod(age * 0.9 + j * 0.5 + i * 0.23, 1.0)
			var mote : Vector2 = tether[roundi(travel * (tether.size() - 1))]
			draw_texture_rect(GLOW_TEXTURE, Rect2(mote - Vector2.ONE * 3.0, Vector2.ONE * 6.0), false, Color(1.0, 1.0, 1.0, 0.8))
	LightningClass.draw_bolt_mesh(self, meshPoints, meshColors, meshIndices)

func get_tether(from : Vector2, to : Vector2, index : int) -> PackedVector2Array:
	var tether : PackedVector2Array = []
	var side : Vector2 = from.direction_to(to).orthogonal()
	var segments : int = maxi(ceili(from.distance_to(to) / 3.0), 4)
	for k in segments + 1:
		var t : float = float(k) / segments
		var wave : float = sin(t * TAU * 1.5 - age * 7.0 + index) * sin(t * PI) * 2.2
		tether.append(from.lerp(to, t) + side * wave)
	return tether
