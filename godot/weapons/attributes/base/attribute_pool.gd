extends Resource
class_name AttributePoolClass


@export var attributes : Array[AttributeClass]
@export var maxAttributes : int = 5

#------------------------#

func roll_attributes(item : WeaponItemClass, kept : Array[AttributeRollClass] = []) -> Array[AttributeRollClass]:
	var weapon : WeaponClass = item.create_weapon()
	var rolls : Array[AttributeRollClass] = []
	for fixed in weapon.fixedAttributes:
		add_roll(rolls, fixed.duplicate() as AttributeRollClass)
	for roll in kept:
		add_roll(rolls, roll)
	var slots : int = 0
	if item.rarity:
		slots = mini(item.rarity.attributeSlots, maxAttributes)
	while rolls.size() < slots:
		var attribute : AttributeClass = pick_attribute(weapon, item.rarity, rolls)
		if not attribute:
			break
		var roll : AttributeRollClass = AttributeRollClass.new()
		roll.attribute = attribute
		roll.quality = randf()
		rolls.append(roll)
	weapon.free()
	return rolls

func add_roll(rolls : Array[AttributeRollClass], roll : AttributeRollClass) -> void:
	if not roll.attribute:
		return
	for existing in rolls:
		if existing.attribute == roll.attribute:
			return
	rolls.append(roll)

func pick_attribute(weapon : WeaponClass, rarity : RarityClass, rolls : Array[AttributeRollClass]) -> AttributeClass:
	var chosen : Array[AttributeClass] = []
	var specials : int = 0
	for roll in rolls:
		chosen.append(roll.attribute)
		if roll.attribute.special:
			specials += 1
	var candidates : Array[AttributeClass] = []
	var totalWeight : float = 0.0
	for attribute in attributes:
		if not attribute.inRandomPool or chosen.has(attribute) or attribute.weight <= 0.0:
			continue
		if attribute.special and specials >= rarity.maxSpecialAttributes:
			continue
		if attribute.can_roll(weapon, chosen):
			candidates.append(attribute)
			totalWeight += attribute.weight
	if candidates.is_empty():
		return null
	var pick : float = randf() * totalWeight
	for attribute in candidates:
		pick -= attribute.weight
		if pick < 0.0:
			return attribute
	return candidates.back()
