extends Control
tool


export(Texture) var texture_when_mouse_is_out setget update_principal_textue
export(Texture) var texture_when_mouse_is_in
export(Texture) var texture_when_is_disabled

export(float, -9999, 9999, 0.1) var min_value = -1
export(float, -9999, 9999, 0.1) var max_value = 1
export(bool) 					var warp_scroll = true

enum MODE {Horizontal, Vertical}
export(MODE) var style setget update_style
export(bool) var disabled = false setget disable

var _texture

var drag = false
var center
var extra_value = 0
var current_value
var initial_position

onready var _texture_button	= $texture

signal value_changed(_value)
signal reset(current_value)
signal dblClick()

func _ready() -> void:
	_texture = $texture
	if !Engine.is_editor_hint():
		_texture.hint_tooltip = hint_tooltip
		hint_tooltip = ""
	update_image()
	set_initial_position()
	connect_signals()
	
func connect_signals():
	if !_texture_button.is_connected("gui_input", self, "_on_texture_gui_input"):
		_texture_button.connect("gui_input", self, "_on_texture_gui_input")

func update_principal_textue(tex : Texture) -> void:
	texture_when_mouse_is_out = tex
	if Engine.is_editor_hint():
		update_image()
	
func update_style(_mode) -> void:
	style = _mode
	if Engine.is_editor_hint():
		update_image()
		#update_size()
		set_initial_position()
		
func update_size():
	rect_size = Vector2(rect_size.y, rect_size.x)
	
func disable(value) -> void:
	disabled = value
	if Engine.is_editor_hint():
		update_image()
	
func update_image()->void:
	if _texture == null: return
	if disabled:
		_texture.texture = texture_when_is_disabled
	else:
		_texture.texture = texture_when_mouse_is_out
		
func set_initial_position():
	_texture.rect_global_position = (
		rect_global_position +
		rect_size * 0.5 -
		_texture.rect_size * 0.5
	)
	center = _texture.rect_global_position


func _on_Customslider_item_rect_changed() -> void:
	if Engine.is_editor_hint():
		set_initial_position()


func _on_texture_gui_input(event: InputEvent) -> void:
	if disabled: return
	if (event is InputEventMouseButton and event.button_index == 1 and
		event.doubleclick):
		emit_signal("dblClick")
		return
			
	if (!drag and event is InputEventMouseButton and
		event.button_index == 1 and event.pressed):
		drag = true
		initial_position = event.position
	elif (event is InputEventMouseButton and
		event.button_index == 1 and !event.pressed):
		emit_signal("reset", current_value)
		_texture.rect_global_position = center
		if drag:
			drag = false
			extra_value = 0
	elif (event is InputEventMouseMotion and drag):
		if event.position != initial_position:
			move_with_mouse()
		
func move_with_mouse():
	var s = _texture.rect_size * 0.5
	var last_position = _texture.rect_global_position
	if style == MODE.Horizontal:
		_texture.rect_global_position.x = get_global_mouse_position().x - s.x
		if (_texture.rect_global_position.x < rect_global_position.x - s.x or
			_texture.rect_global_position.x > rect_global_position.x + rect_size.x - s.x):
			if warp_scroll:
				_texture.rect_global_position.x = center.x
				Input.warp_mouse_position(_texture.rect_global_position + s)
				if last_position.x < center.x:
					extra_value += min_value
				else:
					 extra_value -= min_value
			else:
				if _texture.rect_global_position.x < rect_global_position.x - s.x:
					_texture.rect_global_position.x = rect_global_position.x - s.x
				else:
					_texture.rect_global_position.x = rect_global_position.x + rect_size.x - s.x
			return
	else:
		_texture.rect_global_position.y = get_global_mouse_position().y - s.y
		if (_texture.rect_global_position.y < rect_global_position.y - s.y or
			_texture.rect_global_position.y > rect_global_position.y + rect_size.y - s.y):
			if warp_scroll:
				_texture.rect_global_position.y = center.y
				Input.warp_mouse_position(_texture.rect_global_position + s)
				if last_position.y < center.y:
					extra_value += min_value
				else:
					 extra_value -= min_value
			else:
				if _texture.rect_global_position.y < rect_global_position.y - s.y:
					_texture.rect_global_position.y = rect_global_position.y - s.y
				else:
					_texture.rect_global_position.y = rect_global_position.y + rect_size.y - s.y
			return
	
	if style == MODE.Horizontal:
		var _value = get_real_value(rect_global_position.x,
			rect_global_position.x + rect_size.x,
			get_global_mouse_position().x) + extra_value
		emit_signal("value_changed", _value)
		current_value = _value 
	else:
		var _value = get_real_value(rect_global_position.y,
			rect_global_position.y + rect_size.y,
			get_global_mouse_position().y) + extra_value
		emit_signal("value_changed", _value)
		current_value = _value
		
func get_real_value(minInput, maxInput, input):
	var minOutput = min_value
	var maxOutput = max_value
	var output = ((input - minInput) / (maxInput - minInput) *
				(maxOutput - minOutput) + minOutput)
	return output
	
func get_current_value():
	var value
	if style == MODE.Horizontal:
		value = get_real_value(rect_global_position.x,
			rect_global_position.x + rect_size.x,
			_texture.rect_global_position.x)
	else:
		value = get_real_value(rect_global_position.y,
			rect_global_position.y + rect_size.y,
			_texture.rect_global_position.y)
	return value
	
func get_center_value():
	var value
	if style == MODE.Horizontal:
		value = get_real_value(rect_global_position.x,
			rect_global_position.x + rect_size.x,
			center.x)
	else:
		value = get_real_value(rect_global_position.y,
			rect_global_position.y + rect_size.y,
			center.y)
	return value


func _on_texture_mouse_entered() -> void:
	if disabled: return
	if texture_when_mouse_is_in is Texture:
		_texture.texture = texture_when_mouse_is_in


func _on_texture_mouse_exited() -> void:
	if disabled: return
	if texture_when_mouse_is_out is Texture:
		_texture.texture = texture_when_mouse_is_out
