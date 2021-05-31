extends Node

# Declare member variables here. Examples:
var PORT = 2133
var DEFAULT_IP = "139.177.197.19"
var network = NetworkedMultiplayerENet.new()
var connected_global : bool = false

# board related
var scene_prefab = preload("res://Scene.tscn")

# session specifics
var has_session = false
var scene : ChessScene = null
var board : Main = null # Main type
var enemy_id : int = -1
var team_index = 0

# ui stuff
onready var code_enter : LineEdit = get_tree().get_root().get_node("MainMenu/CodeEnter")
onready var close_session_button : TextureButton = get_tree().get_root().get_node("MainMenu/Host/CloseSession")
var text_popup_prefab = preload("res://Instances/TextPopup.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_to_server()

# -- GLOBAL SERVER RELATED START -- 

func connect_to_server():
	network.create_client(DEFAULT_IP, PORT)
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "on_connected_failed")
	network.connect("connection_succeeded", self, "on_connection_succeeded")
	
func on_connection_failed():
	print("Failed to connect to global server...")

func on_connection_succeeded():
	connected_global = true
	print("Connection successful to global server!")

# -----------------------------------------

# -- CREATING, CLOSING, JOINING, LEAVING SESSION START --
	
func connect_to_session(code : String):
	if has_session: # Don't let the player connect to a session if they already own one
		print("Already in a session! Current session code: " + code)
		return
		
	rpc_id(1, "join_session_by_code", code)
	print("Sent request to Game server: " + code)

remote func on_session_connection():
	print("Successfully connected to session!")
	create_session_scene()
	has_session = true
	team_index = 1 # we must be black team, as we joined the game

func request_new_session():
	if !has_session: # Don't let the player create another session when they already have one
		rpc_id(1, "create_session")
	else:
		print("We are already hosting a session! Code: " + code_enter.text)
	
remote func on_new_session_success(session_code):
	print("Successfully created a new session: " + str(session_code))
	create_session_scene()
	set_code_text(session_code)
	has_session = true # we have a session now! Don't let us join another one or create another one
	close_session_button.visible = true
	
func request_close_session(): # If the host wants to close their session
	rpc_id(1, "host_request_close_session")
	
remote func on_session_close_request_success():
	session_close()
	reset_ui()

func request_disconnect_session():
	rpc_id(1, "disconnect_session")
# -----------------------------------------

# -- LOCAL MANAGEMENT START --

func create_session_scene():
	scene = scene_prefab.instance()
	scene.visible = false
	board = scene.get_node("Main") # Main position
	add_child(scene)
	
func set_ui_visibility(state : bool):
	var ui = get_tree().get_root().get_child(1)
	ui.get_node("Main Camera").current = state
	ui.visible = state

func set_scene_visibility(state: bool):
	scene.get_node("Scene Camera").current = state
	scene.visible = state
	
func set_code_text(code):
	code_enter.text = code
	code_enter.editable = false
	
func reset_ui():
	code_enter.editable = true
	code_enter.text = "CODE"
	close_session_button.visible = false
	
func create_text_popup(text):
	var instance : TextPopup = text_popup_prefab.instance()
	add_child(instance)	
	instance.set_text(text)
	
	
func _input(event):
	if event.is_action_pressed("close"):
		if has_session and enemy_id != -1:
			request_disconnect_session()
	

# -----------------------------------------

# -- STARTING/CLOSING THE ACTUAL SESSION --

remote func session_start(id : int):
	enemy_id = id
	set_scene_visibility(true)
	set_ui_visibility(false)
	has_session = true
	scene.started = true
	
	if team_index == 1: # are we black team?
		scene.flip()
	
remote func session_close(message : String = ""):
	set_scene_visibility(false)
	set_ui_visibility(true)
	reset_ui()
	enemy_id = -1
	has_session = false
	team_index = 0
	
	# delete previous board
	scene.queue_free()
	
	if message != "":
		Server.create_text_popup(message)
	
# -----------------------------------------

# -- MAKING THE ACTUAL MOVES !!! --

func upload_move(a,b,c,d, swap):
	if enemy_id == -1: # don't upload the move if we dont have an opponent!
		return
		
	rpc_id(enemy_id, "process_move", a,b,c,d, swap)
	

remote func process_move(a,b,c,d, swap):
	var move = board.decipher_move_indexes(int(a),int(b),int(c),int(d), swap)
	board.update_session_info(move)
	board.move(move)
#	print(board.decipher_move_indexes(int(a),int(b),int(c),int(d)).taken_piece)
# -----------------------------------------

# -- PROCESSING SESSION UPDATES --

func upload_piece_upgrade(piece_index, state):
	if enemy_id == -1:
		return
		
	rpc_id(enemy_id, "process_piece_upgrade", piece_index, state)

remote func process_piece_upgrade(piece_index, state):
	board.set_piece_upgraded_state(board.pieces[piece_index], state)
