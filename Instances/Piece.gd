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
var times_moved = 0 # how many times has this piece moved?
var possible_moves = [] # type Move
var has_moved : bool = false

# unique data concept
var unique_data = []

# upgraded concept
var upgraded : bool = false
var default_texture : Resource = null
var upgraded_texture : Resource = null

# Called when the node enters the scene tree for the first time.
func _ready():
	main_ref = tile.main_ref
	team_prefix = "white_" if team_index == 0 else "black_"
	set_piece_type(piece_type)
	initialize_unique_data()
	
func initialize_unique_data():
	unique_data.resize(10)
	
func set_piece_type(new_piece_type : int):
	piece_type = new_piece_type
	default_texture = load("res://Sprites/"+team_prefix+PieceType.new().PIECES[piece_type].to_lower()+".png")
	upgraded_texture = load("res://Sprites/"+team_prefix+PieceType.new().PIECES[piece_type].to_lower()+"_upgraded.png")
	
	texture = default_texture

func search_for_path_block(input_array, pierce_amount : int = 0):
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
				if pierce_amount <= 0:
					break
				else:
					pierce_amount -= 1
					continue
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
	
func is_possible_move(move_tile):
	for move in possible_moves:
		if move.end_tile == move_tile:
			return true
	return false

func get_possible_move(end_tile):
	for move in possible_moves:
		if move.end_tile == end_tile:
			return move

func generate_possible_moves(): # this is gonna be messy...
	possible_moves.clear()
	
	var generation = []
	match piece_type:
		0: # pawn ( i should probably try cleaning up this code ) 
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
					
			# en passant
			var start_y = 1 if team_index == 0 else 6 # where does the team's pawns start?
			var fifth_rank = start_y+(y*3) # get the current team's fifth rank
			
			if tile.tile_pos.y == fifth_rank: # capturing pawn must be on its fifth rank
				var adjacents = []
				adjacents.append(main_ref.position_to_tile(Vector2(tile.tile_pos.x-1, tile.tile_pos.y))) # left
				adjacents.append(main_ref.position_to_tile(Vector2(tile.tile_pos.x+1, tile.tile_pos.y))) # right
				for adjacent in adjacents: # typeof tile
					if adjacent == null:
						continue
						
					if adjacent.has_enemy_piece(team_index) and adjacent.has_piece_type(0): # 0 for pawn
						if adjacent.piece.times_moved == 1: # the captured pawn must have only moved in a double step
							if main_ref.last_move.move_piece == adjacent.piece: # the capture can only be made on the move immediately after the enemy pawn makes the double-step move; otherwise, the right to capture it en passant is lost.
								generation.append(Move.new(tile, main_ref.position_to_tile(Vector2(adjacent.tile_pos.x, adjacent.tile_pos.y+y)), self, adjacent.piece))
				pass
			
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
			
			if upgraded: # remove surrounding tiles that are occupied for upgraded queen
				var st = tile.get_surrounding_tiles()
				for t in st:
					if t.has_enemy_piece(team_index):
						for m in generation:
							if m.end_tile == t:
								generation.erase(m)
		5: # king
			var s = tile.get_surrounding_tiles()
			for t in s:
				if t.has_piece() and t.has_enemy_piece(team_index):
					generation.append(Move.new(tile, t, self, t.piece))
				elif !t.has_piece():
					generation.append(Move.new(tile, t, self, null))
		
	# upgraded queen limitations !
	var st = tile.get_surrounding_tiles()
	
	for t in st:
		if t.has_enemy_piece(team_index):
			if t.piece.piece_type == 4 and t.piece.upgraded: # surroundings has an upgraded queen, can't move!
				generation.clear()
				
	# upgraded rook limitations
	for m in generation:
		if piece_type == 1:
			if m.taken_piece != null:
				generation.erase(m)
		
		if m.taken_piece != null:
			if m.taken_piece.piece_type == 1 and m.taken_piece.upgraded:
				generation.erase(m)
	return generation
	
func generate_upgraded_moves():
	var generation = []
	
	match piece_type:
		1: # rook
			pass
		2: # knight
			var a = []
			var tp = tile.tile_pos
			a.append(Vector2(tp.x+2, tp.y))
			a.append(Vector2(tp.x-2, tp.y))
			a.append(Vector2(tp.x, tp.y+2))
			a.append(Vector2(tp.x, tp.y-2))
			
			for b in a:
				var t = main_ref.position_to_tile(b)
				if t != null:
					if t.is_placeable(team_index):
						var p = t.get_enemy_piece(team_index)
						generation.append(Move.new(tile, t, self, p))
		3: # bishop
			var data = []
			data.append_array(search_for_path_block(tile.get_up_left(), 1))
			data.append_array(search_for_path_block(tile.get_up_right(), 1))
			data.append_array(search_for_path_block(tile.get_down_left(), 1))
			data.append_array(search_for_path_block(tile.get_down_right(), 1))
			
			generation.append_array(data)
			
			for move in data: # dont let the upgraded bishop pierce to the king!
				if move.taken_piece != null:
					if move.taken_piece.piece_type == 5: # 5 is king?
						generation.erase(move)
		4: # queen
			pass
		5: # king
			for p in get_team().alive_pieces():
				var move = Move.new(tile, p.tile, self, p, true)
				generation.append(move)
		
	return generation
	
func set_upgraded_state(state : bool):
	upgraded = state
	texture = default_texture if !state else upgraded_texture
	
	var t : Team = get_team()
	if state:
		t.upgraded_pieces.append(self)
	else:
		if t.upgraded_pieces.has(self):
			t.upgraded_pieces.erase(self)
	
func generate_legal_moves(moves):
	var legal_moves = []
	var enemy_team = get_team().get_enemy_team()
	for move in moves:
		main_ref.move(move, true) # simulate the move
		if !enemy_team.has_enemy_in_check():
			legal_moves.append(move)
		main_ref.undo_move(move, true) # un-simulate it lol
	legal_moves.append_array(add_castles(enemy_team))
			
	legal_moves.append(Move.new(tile, tile, self, null)) # always allow the user to put the piece back	
	
	
	return legal_moves

func add_en_passants():
	pass

func add_castles(enemy_team): # super messy lol
	var castles = []
	var tiles = main_ref.tiles
	if piece_type == 5: # are we a king? # unique data will be in the form of moves for the rook
		
		if has_moved: # cant castle if the king has moved
			cant_castle_side(0)
			cant_castle_side(1)
			return castles
			
		if enemy_team.has_enemy_in_check():
			cant_castle_side(0)
			cant_castle_side(1)
			return castles
		
		var start_index = team_index * (56)
		var start_tile = tiles[start_index]
		var king_index = start_index+4
		if start_tile.has_piece() and !start_tile.has_enemy_piece(team_index): # checking the left side
			if start_tile.has_piece_type(1) and !start_tile.piece.has_moved: # rook on the left present
				for i in range(start_index+1, king_index):
					if tiles[i].has_piece(): # blocked
						cant_castle_side(0)
						break
					if enemy_team.is_attacking_tile(tiles[i]): # enemy is attacking the path
						cant_castle_side(0)
						break
						
					if i == start_index+3: # path is clear, dude can castle queen side
						castles.append(Move.new(tile, tiles[start_index+2], self, null))
						unique_data[0] = Move.new(start_tile, tiles[start_index+3], start_tile.piece, null)
			else:
				cant_castle_side(0)
		else:
			cant_castle_side(0)
		
		# castling king side
		var end_index = start_index+7
		var end_tile = tiles[end_index]
		if end_tile.has_piece() and !end_tile.has_enemy_piece(team_index): # checking the right side
			if end_tile.has_piece_type(1) and !end_tile.piece.has_moved: # rook on the right  present
				for i in range(king_index+1, end_index):
					if tiles[i].has_piece(): # blocked
						cant_castle_side(1)
						break
					if enemy_team.is_attacking_tile(tiles[i]): # enemy is attacking the path
						cant_castle_side(1)
						break

					if i == end_index-1: # path is clear, dude can castle king side
						castles.append(Move.new(tile, tiles[end_index-1], self, null))
						unique_data[1] = Move.new(end_tile, tiles[start_index+5], end_tile.piece, null)
			else:
				cant_castle_side(1)
		else:
			cant_castle_side(1)

	return castles

func cant_castle_side(index : int):
	unique_data[index] = null

func set_tile(new_tile):
	tile = new_tile
	position = tile.position
	
func get_team() -> Team:
	return main_ref.teams[team_index]


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
