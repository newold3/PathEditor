extends TextureRect


var textures = {
	"normal"		: preload("Graphics/control_point_normal.png"),
	"normal_start"	: preload("Graphics/control_point_normal_start.png"),
	"normal_end"	: preload("Graphics/control_point_normal_end.png"),
	"sub_normal"	: preload("Graphics/control_subpoint_normal.png"),
	"over"			: preload("Graphics/control_point_over.png"),
	"selected"		: preload("Graphics/control_point_focused.png")
}

var mod_position 			= Vector2(8, 8)
var selected				= false
var id						= 0
var max_points				= 1
var linked_control_points	= true
var show_in					= true # hide in first point
var show_out				= true # hide in last point
var linked_point			= null
var bound					= "none"
var drag					= false

onready var _in 	= $InPoint
onready var _out 	= $OutPoint

signal position_changed(_point_id, _sub_point_id, _position)
signal selected(_point_id, _sub_point_id)
signal deleted(_point_id, _sub_point_id, _control_point)
signal under_cursor()
signal copied(_point_id)
signal pasted(_point_id)

func _ready():
	texture = textures.normal
	_in.texture = textures.sub_normal
	_out.texture = textures.sub_normal
	_in.update()
	_out.update()
	
	connect_signals()
	
func connect_signals():
	if !is_connected("gui_input", self, "_on_ControlPoint_gui_input"):
		connect("gui_input", self, "_on_ControlPoint_gui_input")
	if !_in.is_connected("gui_input", self, "_on_InPoint_gui_input"):
		_in.connect("gui_input", self, "_on_InPoint_gui_input")
	if !_out.is_connected("gui_input", self, "_on_OutPoint_gui_input"):
		_out.connect("gui_input", self, "_on_OutPoint_gui_input")
	
func set_linked_point(_point):
	linked_point = _point
	_point.visible = false
	set_visibility_for_control_points(true, true)
	update_position_of_the_linked_point()
	
func remove_linked_point():
	if linked_point != null:
		linked_point.visible = true
		linked_point = null
	
	
func set_id(_id, _bound="none", _max_points = 1):
	id = _id
	max_points = _max_points
	bound = _bound
	if bound == "top_left":
		show_in = false
		show_out = true
	elif bound == "top_right":
		show_in = true
		show_out = false
	if max_points != 1:
		if id == max_points - 1:
			texture = textures.normal_end
		elif id == 0:
			texture = textures.normal_start
		else:
			texture = textures.normal
	else:
		texture = textures.normal
	_in.texture = textures.sub_normal
	_out.texture = textures.sub_normal
	_in.update()
	_out.update()
	show_control_points(true)	
	update()
	
func set_visibility_for_control_points(_in_is_visible, _out_is_visible):
	show_in = _in_is_visible
	show_out = _out_is_visible
	show_control_points(true)
	
func set_in_position(_pos):
	_in.rect_position = _pos
	show_control_points(true)
	
func set_out_position(_pos):
	_out.rect_position = _pos
	show_control_points(true)
	
func update_position_of_the_linked_point():
	linked_point._in.rect_position 		= _in.rect_position
	linked_point._out.rect_position 	= _out.rect_position
	linked_point.rect_global_position 	= rect_global_position
	linked_point.show_in 				= show_in
	linked_point.show_out 				= show_out
	linked_point.linked_control_points 	= linked_control_points
	emit_signal("position_changed", linked_point.id, 0, rect_global_position, false)
	emit_signal("position_changed", linked_point.id, 1, _in.rect_position, false)
	emit_signal("position_changed", linked_point.id, 2, _out.rect_position, false)
	emit_signal("position_changed", id, 0, rect_global_position, false)
	
	
func select(value):
	selected = value
	if selected:
		texture = textures.selected
	else:
		if max_points != 1:
			if id == max_points - 1:
				texture = textures.normal_end
			elif id == 0:
				texture = textures.normal_start
			else:
				texture = textures.normal
		else:
			texture = textures.normal
	_in.visible = _in.rect_position != Vector2.ZERO and value and show_in
	_out.visible = _out.rect_position != Vector2.ZERO and value and show_out
	update()
	
func show_control_points(value, set_linked_control_points = false):
	_in.visible = _in.rect_position != Vector2.ZERO and value and selected and show_in
	_out.visible = _out.rect_position != Vector2.ZERO and value and selected and show_out
	update()
	if set_linked_control_points:
		linked_control_points = _in.rect_position == -(_out.rect_position)
	# apply correct modulate (based in linked_control_points)
	var mod_color = (Color(0, 1, 0) if !linked_control_points else Color.white)
	_in.modulate = mod_color
	_out.modulate = mod_color
	
func update_position(_id, _position):
	if		_id == 0:
		rect_global_position = _position
	elif	_id == 1:
		_in.rect_position = _position
		if linked_control_points and show_out:
			_out.rect_position = -_in.rect_position
	elif	_id == 2:
		_out.rect_position = _position
		if linked_control_points and show_in:
			_in.rect_position = -_out.rect_position
	
func delete(_sub_id):
	emit_signal("deleted", id, _sub_id, self)
	if linked_point != null: linked_point.delete(_sub_id)
	pass
	
func _input(event: InputEvent) -> void:
	if (event is InputEventKey and
		event.scancode == KEY_SHIFT and
		event.is_pressed()):
		_in.visible = true if show_in else false
		_out.visible = true if show_out else false
		update()
	elif (event is InputEventKey and
		event.scancode == KEY_SHIFT and
		!event.is_pressed()):
		show_control_points(true)
	elif (selected and
		event is InputEventKey and
		event.scancode == KEY_CONTROL
		and event.is_pressed() and
		!event.echo):
		linked_control_points = !linked_control_points
		var mod_color = (Color(0, 1, 0) if !linked_control_points else
			Color.white)
		_in.modulate = mod_color
		_out.modulate = mod_color
	elif (event.is_action_pressed("CTRL + C")):
		emit_signal("copied", id)
	elif (event.is_action_pressed("CTRL + V")):
		emit_signal("pasted", id)
	elif event is InputEventMouseButton and event.button_index == 1 and !event.is_pressed():
		drag = false

func check_input(event, _sub_id):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			select(true)
			emit_signal("selected", id, _sub_id)
			drag = true
		else:
			drag = false
	elif event is InputEventMouseButton and event.button_index == 2 and event.is_pressed():
		delete(_sub_id)
	elif event is InputEventMouseMotion and drag:
		show_control_points(true)
		match _sub_id:
			0: # Control Point
				var last_position = rect_global_position
				rect_global_position += event.position - mod_position
				if last_position != rect_global_position:
					emit_signal("position_changed", id, 0, rect_global_position)
				if linked_point != null: update_position_of_the_linked_point()
			1: # In Point
				var last_position = _in.rect_position
				_in.rect_position += event.position - mod_position
				if last_position != _in.rect_position:
					if linked_control_points and show_out:
						_out.rect_position = -_in.rect_position
						emit_signal("position_changed", id, 2, _out.rect_position, false)
					emit_signal("position_changed", id, 1, _in.rect_position)
				if linked_point != null: update_position_of_the_linked_point()
				update()
			2: # Out Point
				var last_position = _out.rect_position
				_out.rect_position += event.position - mod_position
				if last_position != _out.rect_position:
					if linked_control_points and show_in:
						_in.rect_position = -_out.rect_position
						emit_signal("position_changed", id, 1, _in.rect_position, false)
					emit_signal("position_changed", id, 2, _out.rect_position)
				if linked_point != null: update_position_of_the_linked_point()
				update()
		

func _on_ControlPoint_mouse_entered() -> void:
	texture = textures.over
	show_control_points(true)
	emit_signal("under_cursor")


func _on_ControlPoint_mouse_exited() -> void:
	if !selected:
		if max_points != 1:
			if id == max_points - 1:
				texture = textures.normal_end
			elif id == 0:
				texture = textures.normal_start
			else:
				texture = textures.normal
		else:
			texture = textures.normal
	else:
		textures.selected
	show_control_points(true)


func _on_ControlPoint_gui_input(event: InputEvent) -> void:
	check_input(event, 0)


func _on_InPoint_mouse_entered() -> void:
	_in.texture = textures.over


func _on_InPoint_mouse_exited() -> void:
	_in.texture = textures.sub_normal


func _on_InPoint_gui_input(event: InputEvent) -> void:
	check_input(event, 1)


func _on_OutPoint_mouse_entered() -> void:
	_out.texture = textures.over


func _on_OutPoint_mouse_exited() -> void:
	_out.texture = textures.sub_normal


func _on_OutPoint_gui_input(event: InputEvent) -> void:
	check_input(event, 2)
	
func _draw() -> void:
	var font = Label.new().get_font("")
	draw_string(font, Vector2(16, -4), str(id + 1), Color.white)
	if _in.rect_position != _out.rect_position:
		if _in.visible:
			draw_line(_in.rect_position + mod_position, mod_position, Color(1, 1, 1, 0.2), 1)
		if _out.visible:
			draw_line(_out.rect_position + mod_position, mod_position, Color(1, 1, 1, 0.2), 1)


func _on_InPoint_draw() -> void:
	var font = Label.new().get_font("")
	var _position = Vector2(6, 13)
	_in.draw_string(font, _position, "i", Color.black)


func _on_OutPoint_draw() -> void:
	var font = Label.new().get_font("")
	var _position = Vector2(4, 12)
	_out.draw_string(font, _position, "o", Color.black)
