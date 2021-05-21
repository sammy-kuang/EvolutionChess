extends Node

# Declare member variables here. Examples:
var PORT = 2133
var DEFAULT_IP = "127.0.0.1"
var network = NetworkedMultiplayerENet.new()
var connected_global : bool = false

# board related
var scene_prefab = preload("res://Scene.tscn")

# session specifics
var has_session = false
var scene = null
var board : Main = null # Main type
var enemy_id : int = -1


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

# -- CREATING, JOINING, LEAVING SESSION START --
	
func connect_to_session(code : String):
	rpc_id(1, "join_session_by_code", code)
	print("Sent request to Game server: " + code)

remote func on_session_connection():
	print("Successfully connected to session!")
	create_session_scene()

func request_new_session():
	rpc_id(1, "create_session")
	
remote func on_new_session_success():
	print("Successfully created a new session!")
	create_session_scene()
	
# -----------------------------------------

# -- LOCAL MANAGEMENT START --

func create_session_scene():
	scene = scene_prefab.instance()
	scene.visible = false
	board = scene.get_child(1) # Main position
	add_child(scene)
	
func set_ui_visibility(state : bool):
	var ui = get_tree().get_root().get_child(1)
	ui.get_node("Main Camera").current = state
	ui.visible = state

func set_scene_visibility(state: bool):
	scene.get_node("Scene Camera").current = state
	scene.visible = state

# -----------------------------------------

# -- STARTING THE ACTUAL SESSION --

remote func session_start(id : int):
	enemy_id = id
	set_scene_visibility(true)
	set_ui_visibility(false)
	
# -----------------------------------------

# -- MAKING THE ACTUAL MOVES !!! ---

func upload_move(a,b,c,d):
	if enemy_id == -1: # don't upload the move if we dont have an opponent!
		return
		
	rpc_id(enemy_id, "process_move", a,b,c,d)
	

remote func process_move(a,b,c,d):
	board.move(board.decipher_move_indexes(int(a),int(b),int(c),int(d)))
#	print(board.decipher_move_indexes(int(a),int(b),int(c),int(d)).taken_piece)
# -----------------------------------------

