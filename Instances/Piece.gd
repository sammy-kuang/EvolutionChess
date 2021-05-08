extends Sprite
class_name Piece

# Declare member variables here. Examples:
var tile = null # not explicit typing
var main_ref = null
var piece_type : PieceType = PieceType.Pawn
var team : Team = Team.White
var possible_moves = []

var team_prefix = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	main_ref = tile.main_ref
	team_prefix = "white_" if team == Team.White else "black_"
	
func set_piece_type(new_piece_type : PieceType):
	piece_type = new_piece_type
	texture = load("res://Sprites/"+team_prefix+var2str(piece_type).to_lower()+".png")
		

func generate_possible_moves():
	possible_moves.clear()
	
	match piece_type:
		PieceType.Rook:
			pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
