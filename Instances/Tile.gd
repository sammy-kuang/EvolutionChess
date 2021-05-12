extends Sprite
class_name Tile

# ui and general info
var tile_color : Color
var white_tile = true
var tile_pos : Vector2
var index : int = 0
var main_ref = null
var is_highlighted = false

# other tiles
var surrounding_tiles = []

# piece related
var piece : Piece = null
var color_order = [Color.red, Color.orange, Color.yellow, Color.green, Color.skyblue, Color.blue, Color.purple, Color.brown] # just a debug array of rainbow

# Called when the node enters the scene tree for the first time.
func _ready():
	update_color()
	set_label(index as String)
	
	if tile_color == main_ref.black_color: # ui stuff
		get_label().add_color_override("font_color", Color.white)
		
func on_click():
	if(main_ref.mouse_piece == null and piece != null):
		main_ref.pickup(piece)
	elif(main_ref.mouse_piece != null):
		if main_ref.mouse_piece.is_possible_move(self):
			main_ref.drop(main_ref.mouse_piece.get_possible_move(self))
			
func is_placeable(team_index : int) -> bool:
	if has_piece():
		if has_enemy_piece(team_index):
			return true
		else:
			return false
	else:
		return true
		
func get_diagonals_of_direction(direction : Vector2, magnitude : int = 7, invert : bool = false):
	var ret_data = []
	direction = direction.normalized().ceil()
	#print("Target: " + direction as String)
	var diagonals = get_diagonals_magnitude(magnitude)
	for i in range(diagonals.size()):
		var t = diagonals[i]
		var dir : Vector2 = (diagonals[i].tile_pos - tile_pos).normalized().ceil()
		#print(dir as String + ": " + diagonals[i].index as String)
		
		if dir == direction:
			ret_data.append(t)
			#print("Added: " + diagonals[i].index as String)
	
	if invert:
		ret_data.invert()
	
	return ret_data
	
func get_surrounding_tiles():
	if !surrounding_tiles.empty():
		return surrounding_tiles
	
	var h = get_horizontals(1)
	var v = get_verticals(1)
	var t = [get_up_right(1), get_up_left(1), get_down_right(1), get_down_left(1), h, v]
	
	for i in range(t.size()):
		if(!t[i].empty()):
			for j in range(t[i].size()):
				surrounding_tiles.append(t[i][j])
	return surrounding_tiles
	
func get_up_right(magnitude : int = 7):
	return get_diagonals_of_direction(Vector2(1,1), magnitude, false)

func get_down_right(magnitude : int = 7):
	return get_diagonals_of_direction(Vector2(1,-1), magnitude, true)
	
func get_up_left(magnitude : int = 7):
	return get_diagonals_of_direction(Vector2(-1,1), magnitude, false)

func get_down_left(magnitude : int = 7):
	return get_diagonals_of_direction(Vector2(-1,-1), magnitude, true)
	
func get_left(magnitude : int = 7):
	var left = []
	var horizontals = get_horizontals(magnitude)
	
	for i in range(horizontals.size()):
		var t = horizontals[i]
		if t.tile_pos.x < tile_pos.x:
			left.push_front(t)
	return left
	
func get_right(magnitude : int = 7):
	var right = []
	var horizontals = get_horizontals(magnitude)
	
	for i in range(horizontals.size()):
		var t = horizontals[i]
		if t.tile_pos.x > tile_pos.x:
			right.append(t)
	return right

func get_downward(magnitude : int = 7):
	var downward = []
	var verticals = get_verticals(magnitude)
	for i in range(verticals.size()):
		var t = verticals[i]
		if t.tile_pos.y < tile_pos.y:
			downward.push_front(t)
	return downward
	
func get_upward(magnitude : int = 7):
	var downward = []
	var verticals = get_verticals(magnitude)
	for i in range(verticals.size()):
		var t = verticals[i]
		if t.tile_pos.y > tile_pos.y:
			downward.append(t)
	return downward

func get_verticals(magnitude :int = 7):
	var verticals = []
	for i in range(main_ref.get_tiles().size()):
		var t = main_ref.get_tiles()[i]
		
		if t == self:
			continue
			
		if abs(t.tile_pos.y - tile_pos.y) <= magnitude and t.tile_pos.x == tile_pos.x:
			verticals.append(t)
	return verticals
	
func get_horizontals(magnitude :int = 7):
	var horizontals = []
	for i in range(main_ref.get_tiles().size()):
		var t = main_ref.get_tiles()[i]
		
		if t == self:
			continue
			
		if abs(t.tile_pos.x - tile_pos.x) <= magnitude and t.tile_pos.y == tile_pos.y:
			horizontals.append(t)
	return horizontals
		

func get_diagonals():
	var diagonals = []
	for i in range(main_ref.get_tiles().size()):
		var t = main_ref.get_tiles()[i]
		if(t.rank_file_diff() == rank_file_diff() or t.rank_file_sum() == rank_file_sum()) and (t != self):
			diagonals.append(t)
	return diagonals
	
func get_diagonals_of_magnitude(magnitude : int):
	var ret_data = []
	var diagonals = get_diagonals()
	var search_distance = tile_pos.distance_squared_to(Vector2(tile_pos.x+magnitude, tile_pos.y+magnitude))
	
	for i in range(diagonals.size()):
		var dist = tile_pos.distance_squared_to(diagonals[i].tile_pos)
		if(search_distance == dist):
			ret_data.append(diagonals[i])
	
	return ret_data
	
func get_diagonals_magnitude(magnitude : int):
	var return_data = []
	var diagonals = get_diagonals()
	var max_distance = tile_pos.distance_squared_to(Vector2(tile_pos.x+magnitude+1, tile_pos.y+magnitude+1))
	
	for i in range(diagonals.size()):
		var dist = tile_pos.distance_squared_to(diagonals[i].tile_pos)
		if dist < max_distance:
			return_data.append(diagonals[i])
	return return_data

func rank_file_diff():
	return 7 + tile_pos.x - tile_pos.y
	
func rank_file_sum():
	return 7 + tile_pos.y + tile_pos.x
	
func set_piece(new_piece : Piece):
	piece = new_piece

func set_highlight(value : bool, color : Color = main_ref.highlight_color):
	self_modulate = color if value else tile_color
	is_highlighted = value
	
func has_piece():
	return (piece != null)

func get_enemy_piece(team_index : int):
	if has_enemy_piece(team_index):
		return piece
	else:
		return null
	

func has_enemy_piece(team_index : int):
	if(has_piece()):
		return piece.team_index != team_index
	else:
		return false

func get_label():
	return get_child(0).get_child(0)

func set_label(text : String):
	get_child(0).get_child(0).text = text
	
func update_color():
	self_modulate = tile_color

func _on_mouse_entered():
	main_ref.mouse_tile = self


func _on_mouse_exited():
	pass # Replace with function body.
