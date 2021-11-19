extends CanvasLayer

onready var unit_detail = preload("res://Scenes/UnitDetail.tscn")

var _sgn
var is_sidebar_active = false
var is_unitselection_active = false

var prev_pos : Vector2
var prev_off : Vector2

func _ready() -> void:
	_sgn = Globals.connect("update_seed", self, "on_update_seed")
	_sgn = Globals.connect("highlight_tile", self, "on_highlight_tile")
	_sgn = Globals.connect("toggle_sidebar", self, "on_toggle_sidebar")
	_sgn = Globals.connect("select_unit", self, "on_select_unit")
	_sgn = Globals.connect("update_turn", self, "on_update_turn")
	_sgn = Globals.connect("reset_ui", self, "on_reset_ui")
	
	$Sidebar.rect_position.y = get_viewport().size.y

func on_update_seed(rnd_seed) -> void:
	$Debug/SeedLabel.text = "Seed: %d" % rnd_seed

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
		for child in $Sidebar/Container/UnitDetails.get_children():
			$Sidebar/Container/UnitDetails.remove_child(child)
			child.queue_free()
		
		is_sidebar_active = false
		is_unitselection_active = false
	else:
		$Sidebar/Container/TileInfo/TileNameLabel.text = info.tile_name
		$Sidebar/Container/TileInfo/TileImage.texture.region.position = info.tile_region.position
		$Sidebar/Container/YieldInfo/YieldData/YieldCountLabel.text = "%.2f" % info.tile_yield
		
		for index in range(info.units.unit_handler.size()):
			var instance = unit_detail.instance()
			
			instance.unit_detail = info.units.unit_instances[index]
			
			instance.get_node("UnitImage").texture_normal.region.position.y = Globals.ANT_SPRITE_SIZE * info.units.unit_handler[index][0]
			instance.get_node("UnitImage").modulate = Globals.COLOURS[info.units.unit_instances[index].player]
			instance.get_node("UnitCount").text = "%d" % info.units.unit_count[index]
			
			$Sidebar/Container/UnitDetails.add_child(instance)
		
		if $Sidebar/Container/UnitDetails.get_child_count() == 0:
			$Sidebar/Container/UnitInfo.visible = false
		else:
			$Sidebar/Container/UnitInfo.visible = true
		
		is_sidebar_active = true

func _process(_delta : float) -> void:
	var sidebar_target : float
	var unitsel_target : float
	
	if is_sidebar_active and not is_unitselection_active:
		sidebar_target = get_viewport().size.y - $Sidebar/Container/PositionControl.rect_position.y - $Sidebar/Container/PositionControl.rect_size.y
	else:
		sidebar_target = get_viewport().size.y
	
	if is_unitselection_active:
		unitsel_target = get_viewport().size.y - $UnitSelection/Container/PositionControl.rect_position.y - $UnitSelection/Container/PositionControl.rect_size.y
	else:
		unitsel_target = get_viewport().size.y
	
	if $Sidebar.rect_position.y != sidebar_target:
		$Sidebar.rect_position.y = lerp($Sidebar.rect_position.y, sidebar_target, 0.25)
	
	if $UnitSelection.rect_position.y != unitsel_target:
		$UnitSelection.rect_position.y = lerp($UnitSelection.rect_position.y, unitsel_target, 0.25)

func on_update_turn(player : int, player_name : String, data : Game.Player) -> void:
	if player == 0:
		update_hud(data)
	
	$Debug/TurnLabel.text = "Turn : %s" % player_name

func update_hud(data : Game.Player):
	$Data/FoodData/VBoxContainer/FoodLabel.bbcode_text = "%0.*f [color=%s](%c%0.*f)[/color]" % [
		2 if fmod(data.resources[Globals.resource.FOOD], 1) else 0,
		data.resources[Globals.resource.FOOD],
		"#3d875e" if sign(data.added_resources[Globals.resource.FOOD]) else "#e64e4b",
		"+" if sign(data.added_resources[Globals.resource.FOOD]) else "-",
		2 if fmod(data.added_resources[Globals.resource.FOOD], 1) else 0,
		data.added_resources[Globals.resource.FOOD]
	]

func on_reset_ui() -> void:
	is_sidebar_active = false
	is_unitselection_active = false

func on_select_unit(unit : Unit, unit_image : int, unit_count : int) -> void:
	$UnitSelection/Container/SelectorContainer/TextureRect.self_modulate = Globals.COLOURS[unit.player]
	$UnitSelection/Container/SelectorContainer/TextureRect.texture.region.position.y = unit_image
	$UnitSelection/Container/SelectorContainer/TextureRect/UnitCount.text = "%d" % unit_count
	
	$UnitSelection/Container/SelectorContainer/HScrollBar.max_value = unit_count
	$UnitSelection/Container/SelectorContainer/HScrollBar.value = unit_count
	
	is_unitselection_active = true

func _on_EndTurnButton_pressed() -> void:
	Globals.emit_signal("end_turn")

func update_display_value(value : int) -> void:
	$UnitSelection/Container/SelectorContainer/TextureRect/UnitCount.text = "%d" % value

func _on_HScrollBar_value_changed(value):
	update_display_value(value)

func _on_RemoveAllButton_pressed() -> void:
	$UnitSelection/Container/SelectorContainer/HScrollBar.value = 0

func _on_RemoveHalfButton_pressed() -> void:
	var value = $UnitSelection/Container/SelectorContainer/HScrollBar.value
	value -= value / 2
	$UnitSelection/Container/SelectorContainer/HScrollBar.value = int(value)

func _on_AddHalfButton_pressed() -> void:
	var value = $UnitSelection/Container/SelectorContainer/HScrollBar.value
	value += value / 2
	$UnitSelection/Container/SelectorContainer/HScrollBar.value = int(value)

func _on_AddAllButton_pressed() -> void:
	$UnitSelection/Container/SelectorContainer/HScrollBar.value = $UnitSelection/Container/SelectorContainer/HScrollBar.max_value
