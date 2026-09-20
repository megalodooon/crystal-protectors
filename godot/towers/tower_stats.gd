extends Resource
class_name TowerStatsClass


@export var towerName : String
@export var towerScene : PackedScene
@export var description : String

@export_group("Cost")
@export var manaCost : int = 30
@export var upgradeCost : int = 20
@export var upgradeCostPerTier : int = 15
@export_range(0.0, 1.0) var sellRefund : float = 0.5
@export_range(0.0, 1.0) var repairFactor : float = 0.75

@export_group("Stats")
@export var maxTier : int = 5
@export var health : float = 200.0
@export var healthPerTier : float = 0.25
@export var damage : float = 12.0
@export var damagePerTier : float = 0.5
@export var attackCooldown : float = 1.0
@export var attackRange : float = 48.0
@export var maxTargets : int = 3
@export var damageType : DamageTypeClass

#------------------------#

func get_health(tier : int) -> float:
	return health * (1.0 + healthPerTier * float(tier - 1))

func get_damage(tier : int) -> float:
	return damage * (1.0 + damagePerTier * float(tier - 1))

func get_upgrade_cost(tier : int) -> int:
	return upgradeCost + upgradeCostPerTier * (tier - 1)

func get_repair_cost(missingHealth : float) -> int:
	return maxi(ceili(float(manaCost) * repairFactor * missingHealth), 1)

func get_sell_refund(tier : int) -> int:
	var spent : int = manaCost
	for step in range(1, tier):
		spent += get_upgrade_cost(step)
	return int(float(spent) * sellRefund)
