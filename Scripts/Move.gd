extends Node

class_name Move

var start_tile  = null
var end_tile  = null
var move_piece = null
var take_piece = null

func _init(start_tile,end_tile,move_piece,take_piece):
	self.start_tile = start_tile
	self.end_tile = end_tile
	self.move_piece = move_piece
	self.take_piece = take_piece
