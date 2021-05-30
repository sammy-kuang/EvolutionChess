class_name Move

var start_tile  = null
var end_tile  = null
var move_piece = null
var taken_piece = null

func _init(st,et,mp,tp):
	self.start_tile = st
	self.end_tile = et
	self.move_piece = mp
	self.taken_piece = tp

func compare_end_index(index : int):
	return end_tile.index == index
