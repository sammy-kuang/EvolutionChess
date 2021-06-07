extends Node2D
class_name ChessScene

# Declare member variables here. Examples:
onready var main = get_node("Main")

onready var white_label : LineEdit = get_node("White Time")
onready var black_label : LineEdit = get_node("Black Time")
onready var row : Sprite = get_node("row")
onready var column : Sprite = get_node("column")

var black_time = 600
var white_time = 600

var game_over = false
var started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	if game_over or !started:
		return
		
	if main.current_turn == 0:
		white_time -= delta
		white_label.text = seconds_to_time(white_time)
#		print(seconds_to_time(white_time))
	else:
		black_time -= delta
		black_label.text = seconds_to_time(black_time)
#		print(seconds_to_time(black_time))
	
	if white_time <= 0 or black_time <= 0:
		var who = "White" if white_time <= 0 else "Black"
		var reason = who + " has run out of time! Game over!"
		main.set_game_over(true, reason)
		game_over = true


func seconds_to_time(secs):
	secs = int(secs)
	var minutes = secs/60
	var seconds_remaining = secs-(minutes*60)
	
	var min_string = str(stepify(minutes, 1))
	var seconds_string = str(stepify(seconds_remaining, 0.01))

	if seconds_remaining < 10:
		seconds_string="0"+seconds_string
		
	return min_string + ":" + seconds_string
	
func flip():
	black_label.set_rotation(PI)
	white_label.set_rotation(PI)
	row.flip_h = true
	row.flip_v = true
	row.texture = load("res://Sprites/row_black.png")
	column.flip_h = true
	column.flip_v = true
	column.position = Vector2(800-14.5, 400)
	column.texture = load("res://Sprites/column_black.png")
	row.position.y = 10
	main.flip_board()
