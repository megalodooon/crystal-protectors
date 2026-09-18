extends StatusEffectClass
class_name SlowEffectClass


@export_range(0.0, 1.0) var slowAmount : float = 0.2

#------------------------#

func refresh(newEffect : StatusEffectClass) -> void:
	super(newEffect)
	var newSlow : SlowEffectClass = newEffect as SlowEffectClass
	if newSlow:
		slowAmount = maxf(slowAmount, newSlow.slowAmount)

func combine(other : StatusEffectClass) -> void:
	super(other)
	var otherSlow : SlowEffectClass = other as SlowEffectClass
	if otherSlow:
		slowAmount = maxf(slowAmount, otherSlow.slowAmount)

func set_strength(amount : float) -> void:
	slowAmount = clampf(amount, 0.0, 1.0)

func get_speed_multiplier() -> float:
	return 1.0 - slowAmount
