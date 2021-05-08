extends Node2D
class_name Main

# ui fancy stuff
export var white_color : Color = Color.white
export var black_color : Color = Color.black
export var highlight_color : Color = Color.greenyellow
export var piece_offset : float = 0

# tile related
var tile_prefab = preload("res://Instances/Tile.tscn")
var tiles = []
var mouse_tile : Tile = null


# Called when the node enters the scene tree for the first time.
func _ready():
	generate_board()
	
func _process(delta):
	if get_viewport().get_mouse_position().x > 800+piece_offset:
		mouse_tile = null
		
func _input(event):
	if event.is_action_pressed("click"): # we got a click
		if mouse_tile != null:
			mouse_tile.on_click()

func generate_board():
	var index = -1;
	for y in range(0,8):
		for x in range(0,8):
			index += 1
			var instance = tile_prefab.instance()
			var is_light : bool = ((x+y) % 2 != 0)
			var color = white_color if is_light else black_color
			# setting the properties of the tile
			instance.position = Vector2((x*100+50+piece_offset), 800-(y*100+50-piece_offset))
			instance.tile_color = color
			instance.index = index
			instance.tile_pos = Vector2(x, y)
			instance.main_ref = self
			add_child(instance)
			tiles.append(instance)
			
func position_to_tile(position : Vector2):
	for i in range(tiles.size()):
		if tiles[i].tile_pos == position:
			return tiles[i]
			
func get_vector_directions(vector : Vector2):
	var directions = []
	directions.append(Vector2(vector.x, vector.y))
	directions.append(Vector2(-vector.x, vector.y))
	directions.append(Vector2(vector.x, -vector.y))
	directions.append(Vector2(-vector.x, -vector.y))
	return directions
	

func get_tiles():
	return tiles
