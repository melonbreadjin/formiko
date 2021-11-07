extends CanvasLayer

var _sgn

func _ready() -> void:
	_sgn = Globals.connect("update_seed", self, "on_update_seed")
	_sgn = Globals.connect("highlight_tile", self, "on_highlight_tile")

func on_update_seed(rnd_seed) -> void:
	$SeedLabel.text = "Seed: %d" % rnd_seed

func on_highlight_tile(pos, off, zoom) -> void:
	if pos == null:
		$TileHighlight.visible = false
		return
	else:
		$TileHighlight.visible = true
	
	$TileHighlight.rect_position = Vector2(
		Globals.BLOCK_SIZE / zoom.x * floor((pos.x * zoom.x + fmod(off.x * zoom.x, Globals.BLOCK_SIZE * zoom.x)) / Globals.BLOCK_SIZE / zoom.x) - fmod(off.x / zoom.x, Globals.BLOCK_SIZE / zoom.x),
		Globals.BLOCK_SIZE / zoom.y * floor((pos.y * zoom.y + fmod(off.y * zoom.y, Globals.BLOCK_SIZE * zoom.y)) / Globals.BLOCK_SIZE / zoom.y) - fmod(off.y / zoom.y, Globals.BLOCK_SIZE / zoom.y)
	)
	$TileHighlight.rect_size = Vector2(Globals.BLOCK_SIZE, Globals.BLOCK_SIZE)
	$TileHighlight.rect_scale = Vector2(1.0 / zoom.x, 1.0 / zoom.y)
