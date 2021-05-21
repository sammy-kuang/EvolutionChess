class_name Move

var start_tile  = null
var end_tile  = null
var move_piece = null
var taken_piece = null

func _init(start_tile,end_tile,move_piece,taken_piece):
	self.start_tile = start_tile
	self.end_tile = end_tile
	self.move_piece = move_piece
	self.taken_piece = taken_piece

func compare_end_index(index : int):
	return end_tile.index == index
