extends StatusEffectClass
class_name MarkEffectClass


@export var bonus : float = 0.3

#------------------------#

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newMark : MarkEffectClass = newEffect as MarkEffectClass
	if newMark:
		bonus = maxf(bonus, newMark.bonus)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherMark : MarkEffectClass = other as MarkEffectClass
	if otherMark:
		bonus = maxf(bonus, otherMark.bonus)

func set_strength(amount : float) -> void:
	bonus = amount
