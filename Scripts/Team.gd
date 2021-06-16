extends Node
class_name Team

var main_ref = null

var TEAM = {
	0 : "white",
	1 : "black"
}

# pieces and team specific
var pieces = []
var upgraded_pieces = []
var team_index = 0
var in_check : bool = false
var completed_turns = 0
var king = null

func _init(team_number:int = 0, mp = null):
	self.team_index = team_number
	self.main_ref = mp
	

func get_king():
	if king != null:
		return king
		
	for piece in alive_pieces():
		if piece.piece_type == 5: # 5 represents king
			king = piece
			return piece
	push_error("King is null!!!")
	return null # THIS SHOULD NOT OCCUR

static func index_to_team_name(index):
	return "White" if index == 0 else "Black"
	
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

func get_upgradable_piece():
	var arr = alive_pieces()
	randomize()
	arr.shuffle()
	for piece in arr:
		if piece.piece_type != 0 and !piece.upgraded:
			return piece

func get_enemy_team_index():
	return 1 if team_index == 0 else 0	
	
func has_enemy_in_check():
	for piece in alive_pieces():
		var moves = piece.generate_possible_moves()
		
		if piece.upgraded:
			moves.append_array(piece.generate_upgraded_moves())
		
		for move in moves:
			if move.end_tile.index == get_enemy_king().tile.index:
				return true
	return false
	
func pred_enemy_in_check():
	for piece in alive_pieces():
		var moves = piece.possible_moves
		for move in moves:
			if move.end_tile.index == get_enemy_king().tile.index:
				return true
	return false

func is_attacking_tile(tile) -> bool:
	for piece in alive_pieces():
		for move in piece.generate_possible_moves():
			if move.end_tile == tile:
				return true
	return false
	
func can_mate():
	var a = alive_pieces()
	if a.size() == 2:
		for p in a:
			if p.piece_type == 2 or p.piece_type == 3:
				return false
	else:
		return a.size() != 1

func alive_pieces():
	var ret = []
	for piece in pieces:
		if piece.visible == true:
			ret.append(piece)
	return ret	

func generate_moves():
	for piece in alive_pieces():
		var moves = piece.generate_possible_moves()
		
		if piece.upgraded:
			moves.append_array(piece.generate_upgraded_moves())
		
		return moves

func has_legal_moves() -> bool:
	var e_team : Team = get_enemy_team()
	
	var amount = 0
	for piece in alive_pieces():
		var m = piece.generate_possible_moves()
		if piece.upgraded:
			m.append_array(piece.generate_upgraded_moves())
		var l = piece.generate_legal_moves(m).size()-1 # subtract one since we always technically put the piece back
		if l > 0:
			return true
		
		amount += l
	
	return false
