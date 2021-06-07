extends Node2D

onready var join_button : TextureButton = get_node("Join")
onready var cooldown_timer : Timer = get_node("Join/Cooldown")
var code_edit : LineEdit = null

# Called when the node enters the scene tree for the first time.
func _ready(): # here we go
	code_edit = get_node("CodeEnter")


func _on_Host_pressed():
	Server.request_new_session()


func _on_Join_pressed():
	Server.connect_to_session(str(code_edit.text))
	
	# don't let the player spam the join button (don't overload the server with requests)
	cooldown_timer.start()
	join_button.disabled = true



func _on_Cooldown_timeout():
	join_button.disabled = false


func _on_CloseSession_pressed():
	Server.request_close_session()
	print("Close session button pressed")
