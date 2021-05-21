extends Node2D

var join_cooldown = false
var code_edit : LineEdit = null

# Called when the node enters the scene tree for the first time.
func _ready(): # here we go
	code_edit = get_node("CodeEnter")


func _on_Host_pressed():
	Server.request_new_session()


func _on_Join_pressed():
	Server.connect_to_session(str(code_edit.text))



func _on_Cooldown_timeout():
	join_cooldown = false
