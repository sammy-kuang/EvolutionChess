class_name Move

var start_tile  = null
var end_tile  = null
var move_piece = null
var taken_piece = null

# swap instead of take
var swap : bool = false

func _init(st,et,mp,tp, sw : bool = false):
	self.start_tile = st
	self.end_tile = et
	self.move_piece = mp
	self.taken_piece = tp
	self.swap = sw

func compare_end_index(index : int):
	return end_tile.index == index
