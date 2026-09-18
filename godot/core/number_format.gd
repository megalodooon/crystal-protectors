extends RefCounted
class_name NumberFormatClass


const SHORT_FROM : float = 100000.0
const SUFFIXES : Array[String] = ["", "k", "m", "b", "t", "q"]

#------------------------#

static func format(value : float) -> String:
	if absf(roundf(value)) < SHORT_FROM:
		return str(roundi(value))
	var tier : int = 0
	while tier < SUFFIXES.size() - 1 and absf(snappedf(value, 0.01)) >= 1000.0:
		value /= 1000.0
		tier += 1
	return String.num(value, 2).trim_suffix(".0") + SUFFIXES[tier]
