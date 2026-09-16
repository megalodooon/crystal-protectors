extends Resource
class_name RarityClass


@export var rarityName : String
@export var color : Color = Color.WHITE
@export var damageMultiplier : float = 1.0
@export var nextRarity : RarityClass
@export var slashStyle : SlashStyleClass
@export var enchantStyle : EnchantStyleClass
@export var effects : Array[WeaponEffectClass]

#------------------------#
