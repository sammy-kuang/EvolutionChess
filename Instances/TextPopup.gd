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


func on_resized():
	var res = get_viewport().get_visible_rect().size
	var size = dialog.rect_size
	
	dialog.rect_size = Vector2.ZERO # force minimum size
	dialog.rect_position = Vector2(res.x/2 - size.x/2, res.y/2 - size.y/2) # center
