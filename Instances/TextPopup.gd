extends CenterContainer

class_name TextPopup

# Declare member variables here. Examples:
onready var dialog : AcceptDialog = get_node("CanvasLayer/AcceptDialog")
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	dialog.popup()

func set_text(text):
	dialog.dialog_text = text

func _on_AcceptDialog_confirmed():
	queue_free()
