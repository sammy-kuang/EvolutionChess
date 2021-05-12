extends Sprite
class_name Piece

# Declare member variables here. Examples:
# references
var tile = null # no explicit typing
var cached_tile = null
var main_ref = null

# piece type and team
var piece_type = 0 
var team_index = 0
var team_prefix = ""

# moves
var possible_moves = [] # type Move
var has_moved : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	main_ref = tile.main_ref
	team_prefix = "white_" if team_index == 0 else "black_"
	set_piece_type(piece_type)
	
func set_piece_type(new_piece_type : int):
	piece_type = new_piece_type
	texture = load("res://Sprites/"+team_prefix+PieceType.new().PIECES[piece_type].to_lower()+".png")

func search_for_path_block(input_array):
	var ret_data = []
	for i in range(input_array.size()):
		var t = input_array[i]
		var piece = t.piece
		if piece == null:
			ret_data.append(Move.new(self.tile, t, self, null))
		else:
			if piece.team_index == team_index:
				break
			else:
				ret_data.append(Move.new(self.tile, t, self, piece))
				break
	return ret_data

func generate_vertical_moves():
	var data = []
	data.append_array(search_for_path_block(tile.get_upward()))
	data.append_array(search_for_path_block(tile.get_downward()))
	return data
	
func generate_horizontal_moves():
	var data = []
	data.append_array(search_for_path_block(tile.get_left()))
	data.append_array(search_for_path_block(tile.get_right()))
	return data
	
func generate_diagonal_moves():
	var data = []
	data.append_array(search_for_path_block(tile.get_up_left()))
	data.append_array(search_for_path_block(tile.get_up_right()))
	data.append_array(search_for_path_block(tile.get_down_left()))
	data.append_array(search_for_path_block(tile.get_down_right()))
	return data
	
func is_possible_move(tile):
	for move in possible_moves:
		if move.end_tile == tile:
			return true
	return false

func get_possible_move(end_tile):
	for move in possible_moves:
		if move.end_tile == end_tile:
			return move

func clear_pseudo_legals():
	var cache = possible_moves.duplicate()
	possible_moves.clear()
	for move in cache:
		main_ref.move(move, true)
		if !get_team().get_enemy_team().has_enemy_in_check():
			possible_moves.append(move)
		main_ref.undo_move(move, true)

#	var move = possible_moves[4]
#	main_ref.move(move, true)
#	if !get_team().get_enemy_team().has_enemy_in_check():
#		possible_moves.append(move)	

func generate_possible_moves(): # this is gonna be messy...
	possible_moves.clear()
	
	var generation = []
	match piece_type:
		0: # pawn
			var y = 1 if team_index == 0 else -1
			var vec = Vector2(tile.tile_pos.x, tile.tile_pos.y + y)
			var t = main_ref.position_to_tile(vec)
			var up = main_ref.position_to_tile(Vector2(tile.tile_pos.x, tile.tile_pos.y + y*2))
			if t != null: # moving forward
				if t.piece == null:
					generation.append(Move.new(tile, t, self, null))
					
					if up != null:
						if !has_moved and !up.has_piece():
							generation.append(Move.new(tile, up, self, null))		
				
			var left = main_ref.position_to_tile(Vector2(tile.tile_pos.x-1,tile.tile_pos.y+y)) # left
			var right = main_ref.position_to_tile(Vector2(tile.tile_pos.x+1,tile.tile_pos.y+y)) # right
			
			if left != null:
				if left.has_enemy_piece(team_index):
					generation.append(Move.new(tile, left, self, left.piece))
					
			if right != null:
				if right.has_enemy_piece(team_index):
					generation.append(Move.new(tile, right, self, right.piece))
		1: # rook
			generation.append_array(generate_vertical_moves())
			generation.append_array(generate_horizontal_moves())
		2: # knight
			var high = main_ref.get_vector_directions(Vector2(1, 2))
			var low = main_ref.get_vector_directions(Vector2(2, 1))
			
			for h in high:
				var t = main_ref.position_to_tile(h+tile.tile_pos)
				if t != null:
					if t.is_placeable(team_index):
						generation.append(Move.new(tile, t, self, t.get_enemy_piece(team_index)))
			
			for l in low:
				var t = main_ref.position_to_tile(l+tile.tile_pos)
				if t != null:
					if t.is_placeable(team_index):
						generation.append(Move.new(tile, t, self, t.get_enemy_piece(team_index)))
		3: # bishop
			generation.append_array(generate_diagonal_moves())
		4: # queen
			generation.append_array(generate_vertical_moves())
			generation.append_array(generate_horizontal_moves())
			generation.append_array(generate_diagonal_moves())
		5: # king
			var s = tile.get_surrounding_tiles()
			for t in s:
				if t.has_piece() and t.has_enemy_piece(team_index):
					generation.append(Move.new(tile, t, self, t.piece))
				elif !t.has_piece():
					generation.append(Move.new(tile, t, self, null))
		
	
	return generation
	
func generate_legal_moves():
	var moves = generate_possible_moves()
	var legal_moves = []
	var enemy_team = get_team().get_enemy_team()
	for move in moves:
		main_ref.move(move, true)
		if !enemy_team.has_enemy_in_check():
			legal_moves.append(move)
		main_ref.undo_move(move, true)
	legal_moves.append(Move.new(tile, tile, self, null)) # always allow the user to put the piece back

	return legal_moves

func set_tile(new_tile):
	tile = new_tile
	position = tile.position
	
func get_team():
	return main_ref.teams[team_index]


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
