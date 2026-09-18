extends Node
class_name HealthComponentClass


signal health_changed(currentHealth : float, maxHealth : float)
signal died

@export var maxHealth : float = 100.0

var currentHealth : float

#------------------------#

func _ready() -> void:
	currentHealth = maxHealth

func take_damage(amount : float) -> void:
	if currentHealth <= 0.0:
		return
	currentHealth = maxf(currentHealth - amount, 0.0)
	health_changed.emit(currentHealth, maxHealth)
	if currentHealth <= 0.0:
		died.emit()

func heal(amount : float) -> void:
	if currentHealth <= 0.0:
		return
	currentHealth = minf(currentHealth + amount, maxHealth)
	health_changed.emit(currentHealth, maxHealth)
