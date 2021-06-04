class_name Functions

static func array_safe_erase(array, object):
	var clone = []
	for a in array:
		if a != object:
			clone.append(a)
	return clone
