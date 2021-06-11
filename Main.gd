extends Node2D
class_name Main

# ui fancy stuff
export var white_color : Color = Color.white
export var black_color : Color = Color.black
export var highlight_color : Color = Color.greenyellow
export var check_color : Color = Color.red
export var upgraded_move_color : Color = Color.gold
export var piece_offset : float = 0

# tile related
var tile_prefab = preload("res://Instances/Tile.tscn")
var tiles = []
var mouse_tile = null
var border_width : int = 0

# piece related
var piece_prefab = preload("res://Instances/Piece.tscn")
var mouse_piece : Piece = null
var taken_piece : Piece = null
var last_move : Move = null
var pieces = []

# team related
var teams = []
var current_turn = 0

# game data
var game_over : bool = false
var game_turns = 0
var calculate : Thread = null

# audio misc
var move_clip : AudioStream = load("res://Audio/move.wav")


# Called when the node enters the scene tree for the first time.
func _ready():
	generate_board()
	create_teams()
#	parse_fen_string("4k3/Pr6/1R6/1N6/8/8/8/4K2B w - - 0 1")
#	parse_fen_string("4k3/Pr5R/1R/8/8/8/3p3/1K5B w KQkq - 0 1")
	parse_fen_string("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
#	set_piece_upgraded_state(27, true)
	
	
	
func _process(_delta):
	var mouse_pos_x = get_viewport().get_mouse_position().x
	if mouse_pos_x < border_width or mouse_pos_x > 800+border_width+piece_offset:
		mouse_tile = null
		
	if mouse_piece != null:
		mouse_piece.position = get_global_mouse_position()
	
		
func _input(event):
	if event.is_action_pressed("undo") and !Server.has_session:
		get_tree().reload_current_scene()
	
	if game_over: # don't let anymore inputs on the game if the game has ended
		return
	
	if event.is_action_pressed("upgrade") and !Server.has_session:
		if mouse_tile != null:
			if mouse_tile.has_piece():
				set_piece_upgraded_state(pieces.find(mouse_tile.piece), true)
				
	if event.is_action_pressed("debug") and mouse_tile != null:
		print("debug and mouse tile")
		if mouse_tile.has_piece():
			print("has piece")
			mouse_tile.piece.can_en_passant()
		
	
	var mouse_event : bool = event.is_action_pressed("click") or event.is_action_pressed("right_click")
	
	if mouse_event:
		var mouse_index : int = 0 if event.is_action_pressed("click") else 1
		if mouse_tile != null:
			mouse_tile.on_click(mouse_index)

func _exit_tree():
	if calculate != null:
		calculate.wait_to_finish()
			
func pickup(piece : Piece, mouse_index : int = 0):
	# getting
	var m = piece.generate_possible_moves() if mouse_index == 0 else piece.generate_upgraded_moves()
	var c = highlight_color if mouse_index == 0 else upgraded_move_color
#	print(mouse_index)
	# setting
	mouse_piece = piece
	mouse_piece.possible_moves = mouse_piece.generate_legal_moves(m)
	
	piece.cached_tile = piece.tile
	piece.z_index += 1
	# de-linking
	piece.tile.piece = null
	piece.tile = null
	
	# highlighting
	for i in range(mouse_piece.possible_moves.size()):
		mouse_piece.possible_moves[i].end_tile.set_highlight(true, c)
	
	
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
	
#	if !is_simulation:
#		print("not a simulation, altering positions")
	
	if move.swap:
		switch_tile_pieces(mp, tp, st, et, is_simulation)
	else:
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
			mp.z_index -= 1
		
		
	
func set_game_over(state, reason=""):
	game_over = state
	Server.create_text_popup(reason)
	
func switch_tile_pieces(a : Piece, b : Piece, tile_a, tile_b, is_simulation : bool = false):
	a.tile = tile_b
	tile_b.piece = a
	
	b.tile = tile_a
	tile_a.piece = b
	
	if !is_simulation:
#		print("switch tile pieces positional change")
		a.position = tile_b.position
		b.position = tile_a.position

func undo_move(move : Move, was_simulation : bool = false):
	if move.swap:
		move(Move.new(move.end_tile, move.start_tile, move.move_piece, move.taken_piece, move.swap), was_simulation)
		return 
		
	move(Move.new(move.end_tile, move.start_tile, move.move_piece, null), was_simulation)
	var tp = move.taken_piece
	if tp != null:
		var et = move.end_tile
		et.piece = tp
		tp.tile = et
		tp.visible = true


func upgrade_random_piece(team_index):
	var team : Team = teams[team_index]
	var upgradeable_piece = team.get_upgradable_piece()
	
	if upgradeable_piece != null:
		var index = pieces.find(upgradeable_piece)
		set_piece_upgraded_state(index, true, false)

func set_piece_upgraded_state(piece_index : int, state : bool, receiving : bool = true):
	pieces[piece_index].set_upgraded_state(state)
	if Server.connected_global and !receiving:
		Server.upload_piece_upgrade(piece_index, state)

func upload_move_cipher(move : Move, _iter : int = 0):
	if Server.connected_global:
		var cipher = cipher_move_to_indexes(move)
		Server.upload_move(cipher[0], cipher[1], cipher[2], cipher[3], move.swap, _iter)

func cipher_move_to_indexes(move : Move):
	var a = pieces.find(move.move_piece)
	var b = pieces.find(move.taken_piece)
	var c = move.start_tile.index
	var d = move.end_tile.index
	var e = move.swap
	return [a,b,c,d,e]

func decipher_move_indexes(m, t, s, e, swap):
	var mp : Piece = pieces[m]
	var tp : Piece = pieces[t] if t != -1 else null
	var st = tiles[s]
	var et = tiles[e]
	
	return Move.new(st,et,mp,tp, swap)


func update_session_info(move : Move): # yikes. getting a bit messy
	last_move = move # update the last move
	
	var moved_team : Team = teams[current_turn]
	game_turns += 1
	
	move.move_piece.times_moved += 1 
	move.move_piece.has_moved = true
	current_turn = 1 if current_turn == 0 else 0
	
	if move.move_piece.piece_type == 0:
		var target_y = 7 if moved_team.team_index == 0 else 0
		if move.end_tile.tile_pos.y == target_y:
			move.move_piece.set_piece_type(4)
	
	
	if move.taken_piece != null:
		if move.taken_piece.upgraded:
			move.taken_piece.get_team().upgraded_pieces = Functions.array_safe_erase(move.taken_piece.get_team().upgraded_pieces, move.taken_piece)
	
	if moved_team.has_enemy_in_check():
		print("we have the enemy in check!")
		teams[current_turn].get_king().tile.set_highlight(true, check_color)
	else:
		for tile in tiles:
			tile.set_highlight(false)
		
	if Server.has_session and Server.enemy_id != -1 and Server.team_index == 0: # need an opponent, host has timer dominance
		Server.upload_updated_timer()
#		print("Synced timer")
	
	if game_turns % 8 == 0 and Server.team_index == 0:
		upgrade_random_piece(0)
		upgrade_random_piece(1)

	for i in range(2):
		var t : Team = teams[i]
		for piece in t.upgraded_pieces:
			if piece.deupgrade_on == game_turns:
				set_piece_upgraded_state(pieces.find(piece), false, true)
	
	if OS.get_name() != "HTML5":
		calculate = Thread.new()
		var _a = calculate.start(self, "game_over_check", "thread string")
	else:
		var timer : Timer = Timer.new()
		timer.wait_time = 0.075
		timer.autostart = false
		timer.one_shot = true
		timer.connect("timeout", self, "game_over_check")
		add_child(timer)
		timer.start()
		
	Server.play_sound(move_clip)
		
func moved(move : Move):
	var _move_piece = move.move_piece
	
	# store the moves that need to be pushed to the network
	var network_updates = []
	
	# add the current move to the network queue
	network_updates.append(move)
	
	# castle check
	var is_castle = castle_check(move)
	if is_castle != null:
		move(is_castle)
		network_updates.append(is_castle) # add the castle move to the network queue
		
		
	# upload the queued to the network
	for i in range(network_updates.size()):
		var m = network_updates[i]
		upload_move_cipher(m, i)
		
	update_session_info(move) # Update the times moved, the has moved, etc
	

func game_over_check(_thread_string="") -> String:
	var w = teams[0]
	var b = teams[1]

	var whl = w.has_legal_moves()
	var bhl = b.has_legal_moves()
	
	var cur_team : Team = teams[current_turn]
	
	var reason = "None"

	if !w.can_mate() and !b.can_mate():  # assume stalemate?
		reason = "Stalemate! Draw."
	
	if !whl or !bhl:
		reason = "Game over! One team cannot move!"
	
	for team in teams:
		var e_team : Team = team.get_enemy_team()
		var hl = whl if team.team_index == 0 else bhl
		if !hl:
			if !e_team.has_enemy_in_check():
				reason = "Stalemate! Draw."
			else:
				reason = "Checkmate! " + Team.index_to_team_name(e_team.team_index) + " has won!"
	
	if cur_team.has_enemy_in_check():
		reason = "Game over! " + Team.index_to_team_name(current_turn) + " is able to take the other king!"
	
	if reason != "None":
		set_game_over(true, reason)
	
	return reason

func castle_check(move : Move):
	var mp = move.move_piece
	if mp.piece_type == 5: # is king?
		var queen_side = mp.unique_data[0]
		var king_side = mp.unique_data[1]
		var start_index = move.move_piece.team_index * 56
		if queen_side != null: # the user probably could castle queen side
			if move.end_tile.index == start_index+2:
				return queen_side
		
		if king_side != null: # the user probably could castle queen side
			if move.end_tile.index == start_index+6:
				return king_side

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
	var _piece_types = PieceType.new().PIECES
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
			instance.global_position = Vector2((x*100+50+piece_offset), 800-(y*100+50-piece_offset))
			instance.tile_color = color
			instance.index = index
			instance.tile_pos = Vector2(x, y)
			instance.main_ref = self
			instance.white_tile = is_light
			add_child(instance)
			tiles.append(instance)
	
	# set the border width	
	border_width = int((get_viewport().get_visible_rect().size.x-800)/2)
			
			
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
	
func sum_piece_position_indices():
	var r = 0
	for piece in pieces:
		if piece.visible:
			r += piece.tile.index
	return r
	
func flip_board():
	var camera : Camera2D = get_parent().get_node("Scene Camera")
	camera.rotation_degrees = 180
	for piece in pieces:
		piece.flip_v = true
