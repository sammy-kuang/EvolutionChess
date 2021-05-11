extends Node
class_name Team

var main_ref = null

var TEAM = {
	0 : "white",
	1 : "black"
}

var pieces = []
var team_index = 0

func _init(team_index:int = 0, main_ref = null):
	self.team_index = team_index
	self.main_ref = main_ref
	

func get_king():
	for piece in pieces:
		if piece.piece_type == 5: # 5 represents king
			return piece
	push_error("King is null!!!")
	return null # THIS SHOULD NOT OCCUR
	
func get_enemy_king():
	return main_ref.teams[get_enemy_team_index()].get_king()
	
func get_enemy_team():
	return main_ref.teams[get_enemy_team_index()]
	
func print_king():
	print("King is at tile: " + get_king().tile.index as String)
	
func get_random_piece():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var r = rng.randi_range(0, pieces.size())
	return pieces[r]

func get_upgradable_piece(iter : int = 1 ):
	pass #todo kek

func get_enemy_team_index():
	return 1 if team_index == 0 else 0	
	
func has_enemy_in_check():
	for piece in pieces:
		if piece.visible == false: # Piece is taken
			continue
		
		piece.generate_possible_moves(false)
		for move in piece.possible_moves:
			if move.end_tile.index == get_enemy_king().tile.index:
				return true
	return false
		
