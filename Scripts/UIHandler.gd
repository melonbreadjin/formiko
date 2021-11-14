extends CanvasLayer

var _sgn
var is_sidebar_active = false

var prev_pos : Vector2
var prev_off : Vector2

func _ready() -> void:
	_sgn = Globals.connect("update_seed", self, "on_update_seed")
	_sgn = Globals.connect("highlight_tile", self, "on_highlight_tile")
	_sgn = Globals.connect("toggle_sidebar", self, "on_toggle_sidebar")
	_sgn = Globals.connect("update_turn", self, "on_update_turn")
	
	$Sidebar.rect_position.y = get_viewport().size.y

func on_update_seed(rnd_seed) -> void:
	$SeedLabel.text = "Seed: %d" % rnd_seed

func on_highlight_tile(pos, off, zoom) -> void:
	if pos == null:
		$TileHighlight.visible = false
		return
	elif is_sidebar_active:
		if abs($TileHighlight.rect_scale.x - 1.0 / zoom.x) < 0.01:
			return
		else:
			pos = prev_pos
			off = prev_off
	else:
		$TileHighlight.visible = true
	
	$TileHighlight.rect_position = Vector2(
		Globals.BLOCK_SIZE / zoom.x * floor((pos.x * zoom.x + fmod(off.x * zoom.x, Globals.BLOCK_SIZE * zoom.x)) / Globals.BLOCK_SIZE / zoom.x) - fmod(off.x / zoom.x, Globals.BLOCK_SIZE / zoom.x),
		Globals.BLOCK_SIZE / zoom.y * floor((pos.y * zoom.y + fmod(off.y * zoom.y, Globals.BLOCK_SIZE * zoom.y)) / Globals.BLOCK_SIZE / zoom.y) - fmod(off.y / zoom.y, Globals.BLOCK_SIZE / zoom.y)
	)
	$TileHighlight.rect_size = Vector2(Globals.BLOCK_SIZE, Globals.BLOCK_SIZE)
	$TileHighlight.rect_scale = Vector2(1.0 / zoom.x, 1.0 / zoom.y)
	
	prev_pos = pos
	prev_off = off

func on_toggle_sidebar(info : Dictionary) -> void:
	if is_sidebar_active or info.size() == 0:
		is_sidebar_active = false
	else:
		$Sidebar/Container/TileInfo/TileNameLabel.text = info.tile_name
		$Sidebar/Container/TileInfo/TileImage.texture.region.position = info.tile_region.position
		$Sidebar/Container/YieldInfo/YieldData/YieldCountLabel.text = "%.2f" % info.tile_yield
		
		is_sidebar_active = true

func _process(_delta : float) -> void:
	var target : float
	
	if is_sidebar_active:
		target = get_viewport().size.y - 192.0
	else:
		target = get_viewport().size.y
	
	if $Sidebar.rect_position.y != target:
		$Sidebar.rect_position.y = lerp($Sidebar.rect_position.y, target, 0.25)

func on_update_turn(player : String) -> void:
	$TurnLabel.text = "Turn : %s" % player

func _on_EndTurnButton_pressed() -> void:
	Globals.emit_signal("end_turn")
