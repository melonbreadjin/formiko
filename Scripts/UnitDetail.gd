extends Control

var unit_detail : Unit

func _on_UnitImage_pressed() -> void:
	Globals.emit_signal("select_unit", unit_detail, $UnitImage.texture_normal.region.position.y, int($UnitCount.text))
