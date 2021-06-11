extends Node

# Declare member variables here. Examples:
var PORT = 2133
var DEFAULT_IP = "45.79.10.54"
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

var VERSION_CODE = "anVuZTgyMDIw"

# Called when the node enters the scene tree for the first time.
func _ready():
	# we don't want to connect if its single player
	if get_node("/root/").has_node("Scene"):
		print("Single player detected")
		return
	connect_to_server()

# -- GLOBAL SERVER RELATED START -- 

func connect_to_server():
	network.create_client(DEFAULT_IP, PORT)
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "on_connected_failed")
	network.connect("connection_succeeded", self, "on_connection_succeeded")
	network.connect("server_disconnected", self, "on_connection_disconnected")
	
func on_connection_failed():
	print("Failed to connect to global server...")
	create_text_popup("Can't seem to connect to the global server. Are you offline?")

func on_connection_succeeded():
	print("Established link to global server!")
	connected_global = true
	verify_connection_version()
	
func verify_connection_version():
	rpc_id(1, "request_verify", VERSION_CODE)
	
remote func on_verification_success():
	print("Connection verified with global server!")
	
func on_connection_disconnected():
	connected_global = false
	if has_session:
		session_close("Lost connection to global server")
	else:
		create_text_popup("Lost connection to the global server. Are you offline?")
	print("Lost our connection to the global server!")
	

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
	
remote func receive_server_popup(text):
	create_text_popup(text)
	
func play_sound(audio_stream : AudioStream):
	if OS.get_name() == "HTML5":
		return
		
	var audio_player = AudioStreamPlayer.new()
	audio_player.connect("finished", audio_player, "queue_free")
	audio_player.stream = audio_stream
	add_child(audio_player)
	audio_player.play()
	
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

func upload_move(a,b,c,d, swap, iter : int = 0):
	if enemy_id == -1: # don't upload the move if we dont have an opponent!
		return
		
	rpc_id(enemy_id, "process_move", a,b,c,d, swap, bool(iter==0))
	

remote func process_move(a,b,c,d, swap, update : bool = true):
	var move = board.decipher_move_indexes(int(a),int(b),int(c),int(d), swap)
	
	board.move(move)
	
	if update:
		board.update_session_info(move)

# -----------------------------------------

# -- PROCESSING SESSION UPDATES --

func upload_piece_upgrade(piece_index : int, state : bool):
	if enemy_id == -1:
		return
		
	rpc_id(enemy_id, "process_piece_upgrade", piece_index, state)

remote func process_piece_upgrade(piece_index : int, state : bool):
	board.set_piece_upgraded_state(piece_index, state)
	
func upload_updated_timer():
	rpc_id(enemy_id, "receive_updated_timer", scene.white_time, scene.black_time)
	
remote func receive_updated_timer(white_time, black_time):
	scene.white_time = white_time
	scene.black_time = black_time
	
func set_game_over(state, message, upload : bool = false):
	if enemy_id != -1:
		board.set_game_over(state, message)
		scene.game_over = state
		
		if upload:
			rpc_id(enemy_id, "set_game_over", state, message)
