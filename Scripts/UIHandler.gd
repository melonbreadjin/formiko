extends CanvasLayer

var _sgn
var is_sidebar_active = false

func _ready() -> void:
	_sgn = Globals.connect("update_seed", self, "on_update_seed")
	_sgn = Globals.connect("highlight_tile", self, "on_highlight_tile")
	_sgn = Globals.connect("toggle_sidebar", self, "on_toggle_sidebar")
	_sgn = Globals.connect("update_turn", self, "on_update_turn")

func on_update_seed(rnd_seed) -> void:
	$SeedLabel.text = "Seed: %d" % rnd_seed

func on_highlight_tile(pos, off, zoom) -> void:
	if pos == null:
		$TileHighlight.visible = false
		return
	elif is_sidebar_active:
		return
	else:
		$TileHighlight.visible = true
	
	$TileHighlight.rect_position = Vector2(
		Globals.BLOCK_SIZE / zoom.x * floor((pos.x * zoom.x + fmod(off.x * zoom.x, Globals.BLOCK_SIZE * zoom.x)) / Globals.BLOCK_SIZE / zoom.x) - fmod(off.x / zoom.x, Globals.BLOCK_SIZE / zoom.x),
		Globals.BLOCK_SIZE / zoom.y * floor((pos.y * zoom.y + fmod(off.y * zoom.y, Globals.BLOCK_SIZE * zoom.y)) / Globals.BLOCK_SIZE / zoom.y) - fmod(off.y / zoom.y, Globals.BLOCK_SIZE / zoom.y)
	)
	$TileHighlight.rect_size = Vector2(Globals.BLOCK_SIZE, Globals.BLOCK_SIZE)
	$TileHighlight.rect_scale = Vector2(1.0 / zoom.x, 1.0 / zoom.y)

func on_toggle_sidebar(info : Dictionary) -> void:
	if is_sidebar_active:
		is_sidebar_active = false
		$Sidebar.visible = false
	else:
		$Sidebar/Panel/Container/TileInfo/TileNameLabel.text = info.tile_name
		$Sidebar/Panel/Container/TileInfo/TileImage.texture.region.position = info.tile_region.position
		
		is_sidebar_active = true
		$Sidebar.visible = true

func on_update_turn(player : String) -> void:
	$TurnLabel.text = "Turn : %s" % player

func _on_EndTurnButton_pressed() -> void:
	Globals.emit_signal("end_turn")
