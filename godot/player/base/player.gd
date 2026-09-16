extends CharacterBody2D
class_name PlayerClass


const PLACEHOLDER_IMAGE := preload("res://player/base/player_placeholder.png")
const PLACEHOLDER_HAND_IMAGE := preload("res://player/base/hand_placeholder.png")

@export var image : Texture2D
@export var handImage : Texture2D
@export var weaponItem : WeaponItemClass
@export var flipSpeed : float = 10.0
@export var healthComponent : HealthComponentClass
@export var movementComponent : MovementComponentClass

@onready var visuals : Node2D = $Visuals
@onready var sprite : Sprite2D = $Visuals/Sprite2D
@onready var handPivot : Node2D = $HandPivot
@onready var hand : Node2D = $HandPivot/Hand
@onready var handSprite : Sprite2D = $HandPivot/Hand/Sprite2D
@onready var animationPlayer : AnimationPlayer = $AnimationPlayer

var weapon : WeaponClass

#------------------------#

func _ready() -> void:
	if image:
		sprite.texture = image
	else:
		sprite.texture = PLACEHOLDER_IMAGE
	if handImage:
		handSprite.texture = handImage
	else:
		handSprite.texture = PLACEHOLDER_HAND_IMAGE
	if weaponItem:
		equip_weapon(weaponItem)

func _physics_process(delta : float) -> void:
	var mousePosition : Vector2 = get_global_mouse_position()
	handPivot.look_at(mousePosition)
	if weapon:
		handPivot.rotation += weapon.swingRotation
	update_facing(mousePosition, delta)

func equip_weapon(newWeaponItem : WeaponItemClass) -> void:
	if weaponItem and weaponItem.changed.is_connected(on_weapon_item_changed):
		weaponItem.changed.disconnect(on_weapon_item_changed)
	weaponItem = newWeaponItem
	weaponItem.changed.connect(on_weapon_item_changed)
	spawn_weapon()

func spawn_weapon() -> void:
	if weapon:
		weapon.queue_free()
	weapon = weaponItem.create_weapon()
	weapon.wielder = self
	hand.add_child(weapon)
	hand.move_child(weapon, 0)

func on_weapon_item_changed() -> void:
	if (weaponItem.rarity and weapon.rarity != weaponItem.rarity) or weapon.attributes != weaponItem.attributes:
		spawn_weapon()

func update_facing(targetPosition : Vector2, delta : float) -> void:
	var facing : float = 1.0
	if targetPosition.x < global_position.x:
		facing = -1.0
	visuals.scale.x = move_toward(visuals.scale.x, facing, flipSpeed * delta)
