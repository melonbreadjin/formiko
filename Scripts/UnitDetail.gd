extends Control

var unit_detail : Unit
var unit_handler : Array

func _on_UnitImage_pressed() -> void:
	Globals.emit_signal("select_unit", unit_detail, unit_handler, $UnitImage.texture_normal.region.position.y, int($UnitCount.text))
