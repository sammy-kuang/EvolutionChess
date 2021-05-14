extends Node2D
class_name Main

# ui fancy stuff
export var white_color : Color = Color.white
export var black_color : Color = Color.black
export var highlight_color : Color = Color.greenyellow
export var piece_offset : float = 0

# tile related
var tile_prefab = preload("res://Instances/Tile.tscn")
var tiles = []
var mouse_tile = null

# piece related
var piece_prefab = preload("res://Instances/Piece.tscn")
var mouse_piece : Piece = null
var taken_piece : Piece = null
var last_move : Move = null
var pieces = []

# team related
var teams = []


# Called when the node enters the scene tree for the first time.
func _ready():
	generate_board()
	create_teams()
#	parse_fen_string("4k3/r7/8/8/8/8/8/R3K2R w KQkq - 0 1")
	parse_fen_string("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	
	var p = pieces[1]
	var up = p.search_for_path_block(p.tile.get_upward())
	
func _process(_delta):
	if get_viewport().get_mouse_position().x > 800+piece_offset:
		mouse_tile = null
		
	if mouse_piece != null:
		mouse_piece.position = get_viewport().get_mouse_position()
	
		
func _input(event):
	if event.is_action_pressed("click"): # we got a click
		if mouse_tile != null:
			mouse_tile.on_click()
	elif event.is_action_pressed("undo") and last_move != null:
		get_tree().reload_current_scene()
			
func pickup(piece : Piece):
	# setting
	mouse_piece = piece
	mouse_piece.possible_moves = mouse_piece.generate_legal_moves()
	piece.cached_tile = piece.tile
	piece.z_index = 1
	# de-linking
	piece.tile.piece = null
	piece.tile = null
	
	# highlighting
	for i in range(mouse_piece.possible_moves.size()):
		mouse_piece.possible_moves[i].end_tile.set_highlight(true)
	
	
func drop(move : Move):
	# setting
	move(move, false)
	
	# variables
	var friendly_team = move.move_piece.get_team()
	var enemy_team = friendly_team.get_enemy_team()
	
	# highlighting
	for move in mouse_piece.possible_moves:
		move.end_tile.set_highlight(false)
	
	# check checking
	enemy_team.in_check = friendly_team.has_enemy_in_check()
	
	# moved event (did the player just put the piece back into its original spot?)
	if move.end_tile == mouse_piece.cached_tile:
		pass
	else:
		moved(move)
	
	# de-linking
	mouse_piece = null

func move(move : Move, is_simulation : bool = false): # REDO THIS FUNCTION
	var mp : Piece = move.move_piece
	var tp : Piece = move.taken_piece
	var st  = move.start_tile
	var et  = move.end_tile
	
	# taken
	if tp != null:
		tp.visible = false
		tp.tile.piece = null # review that this is actually needed
		tp.tile = null
	
	# start
	st.piece = null
	# end
	et.piece = mp
	mp.tile = et
	if !is_simulation:
		mp.position = et.position
	
	last_move = move
	
func undo_move(move : Move, was_simulation : bool = false):
	move(Move.new(move.end_tile, move.start_tile, move.move_piece, null), was_simulation)
	var tp = move.taken_piece
	if tp != null:
		var et = move.end_tile
		et.piece = tp
		tp.tile = et
		tp.visible = true
	
	
func moved(move : Move):
	var move_piece = move.move_piece
	move_piece.has_moved = true
	
	# castle check
	castle_check(move)

func castle_check(move : Move):
	var mp = move.move_piece
	if mp.piece_type == 5: # is king?
		var queen_side = mp.unique_data[0]
		var king_side = mp.unique_data[1]
		var start_index = move.move_piece.team_index * 7
		if queen_side != null: # the user probably could castle queen side
			if move.end_tile.index == start_index+2:
				move(queen_side)
		
		if king_side != null: # the user probably could castle queen side
			if move.end_tile.index == start_index+6:
				move(king_side)

func add_piece(piece_type : int, team_index : int, tile):
	var instance = piece_prefab.instance()
	instance.main_ref = self
	instance.tile = tile
	instance.piece_type = piece_type
	instance.team_index = team_index
	instance.position = tile.position
	tile.piece = instance
	teams[team_index].pieces.append(instance)
	pieces.append(instance)
	add_child(instance)
	
	
func parse_fen_string(input : String):
	# rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
	var fen = input.split(" ")[0]
	var lines = fen.split("/")
	var piece_types = PieceType.new().PIECES
	var ctoint = { "p" : 0, "r" : 1, "n" : 2, "b" : 3,  "q" : 4, "k" : 5}
	
	for i in range(lines.size()):
		var index = 56 - (8*i)
		for c in lines[i]:
			if c.is_valid_integer():
				index += (c as int)
			elif c.to_upper() == c: # upper case
				add_piece(ctoint[c.to_lower()], 0, tiles[index])
				index+=1
			elif c.to_lower() == c: # lower case
				add_piece(ctoint[c.to_lower()], 1, tiles[index])
				index+=1
	

func create_teams():
	teams.append(Team.new(0, self))
	teams.append(Team.new(1, self))

func generate_board():
	var index = -1;
	for y in range(0,8):
		for x in range(0,8):
			index += 1
			var instance = tile_prefab.instance()
			var is_light : bool = ((x+y) % 2 != 0)
			var color = white_color if is_light else black_color
			# setting the properties of the tile
			instance.position = Vector2((x*100+50+piece_offset), 800-(y*100+50-piece_offset))
			instance.tile_color = color
			instance.index = index
			instance.tile_pos = Vector2(x, y)
			instance.main_ref = self
			instance.white_tile = is_light
			add_child(instance)
			tiles.append(instance)
			
			
func position_to_tile(position : Vector2):
	for i in range(tiles.size()):
		if tiles[i].tile_pos == position:
			return tiles[i]
			
func get_vector_directions(vector : Vector2):
	var directions = []
	directions.append(Vector2(vector.x, vector.y))
	directions.append(Vector2(-vector.x, vector.y))
	directions.append(Vector2(vector.x, -vector.y))
	directions.append(Vector2(-vector.x, -vector.y))
	return directions
	

func get_tiles():
	return tiles
