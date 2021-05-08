extends Node
class_name Team

var TEAM = {
	0 : "white",
	1 : "black"
}

var pieces = []
var team_index = 0

func _init(team_index:int = 0):
	self.team_index = team_index
