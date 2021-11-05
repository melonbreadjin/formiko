extends CanvasLayer

var _sgn

func _ready() -> void:
	_sgn = Globals.connect("update_seed", self, "on_update_seed")

func on_update_seed(rnd_seed) -> void:
	$SeedLabel.text = "Seed: %d" % rnd_seed
