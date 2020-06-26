extends Control

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

var control_point = preload("ControlPoint.tscn")

onready var path_list 						= $Paths/path_list
onready var point_list 						= $Points/point_list
onready var create_path_text				= $create_path_panel/LineEdit
onready var point_x_spinbox 				= $Points/x_SpinBox
onready var point_y_spinbox 				= $Points/y_SpinBox
onready var backed_spinbox 					= $backed_SpinBox
onready var point_container 				= $PointsContainer
onready var canvas							= $Canvas
onready var canvas_layer0					= $Canvas/Layer0
onready var canvas_layer1					= $Canvas/Layer1
onready var canvas_layer2					= $Canvas/Layer2
onready var close_path_button				= $ClosePath_button
onready var close_path_button_label			= $ClosePath_button/label
onready var animated_sprite					= $AnimatedSprite
onready var animation_duration				= $animation_time_SpinBox
onready var stop_buton						= $stop_animation_button
onready var center_points_button 			= $center_points_button
onready var center_points_option_button 	= $center_points_option_button
onready var tween_animation					= $Tween_for_animation
onready var tween_rotate_animation			= $Tween_for_rotate_animation
onready var animation_total_points_label	= $animation_total_points_label
onready var scale_slider					= $scale_points_Slider
onready var move_x_slider					= $move_horizontal_Slider
onready var move_y_slider					= $move_vertical_Slider
onready var rotate_slider					= $rotate_points_Slider
onready var scale_label						= $scale_points_label
onready var scale_spinBox 					= $scale_dialog/SpinBox
onready var dialog_layer					= $hide_behind_controls
onready var scale_dialog					= $scale_dialog
onready var create_path_dialog 				= $create_path_panel
onready var file_dialog						= $CustomFileDialog
onready var path_background					= $Canvas/Background
onready var color_picker					= $ColorPicker
onready var path_color						= $path_color_container/path_color
onready var mirror_option					= $MirrorPointsButtonsContainer/anchor_mode_options
onready var UndoRedo						= $UndoRedo
onready var copy_path_button				= $Paths/copy_path_button
onready var paste_path_button				= $Paths/paste_path_button
onready var duplicate_path_button			= $Paths/duplicate_path_button
onready var deleted_path_button				= $Paths/delete_selected_path_button
onready var copy_point_button				= $Points/copy_point_button
onready var paste_point_button				= $Points/paste_point_button
onready var dialog_move						= $move_dialog
onready var dialog_move_x_spinbox			= $move_dialog/x_SpinBox
onready var dialog_move_y_spinbox			= $move_dialog/y_SpinBox
onready var help_info						= $help_button/help_info
onready var save_paths_LineEdit				= $save_paths_LineEdit
onready var dialog_rotate					= $rotate_dialog
onready var rotate_spinBox 					= $rotate_dialog/SpinBox
onready var canvas_clip_contents_CheckBox	= $canvas_clip_contents_button/canvas_clip_contents_CheckBox
onready var delete_path_dialog 				= $delete_path_dialog
onready var delete_path_dialog_ok_button 	= $delete_path_dialog/ok_button
onready var dialog_move_selector			= $move_dialog/dialog_selector
onready var overwrite_file_paths_dialog		= $replace_file_path_dialog
onready var overwrite_file_paths_itemlist	= $replace_file_path_dialog/ItemList
onready var overwrite_dialog_ok_button		= $replace_file_path_dialog/ok_button
onready var delete_point_button				= $Points/delete_point_button

var data 								= []
var can_update_values 					= true
var closest_point 						= null
var current_path_is_closed 				= false
var animation							= {
	"points"			: null,
	"current_frame"		: 0,
	"reverse_mode"		: false
}
var extra_controls_data = {
	"last_position" 			: null,
	"last_angle" 				: null,
	"last_zoom" 				: null
}
var mod_position = Vector2(8, 8)
var path_line_color = Color.red

class AnimationPosition:
	var offset = 0
	
var Point_Type = {"normal" : 0, "in" : 1, "out" : 2}
	
var animation_position = AnimationPosition.new()
var CLIPBOARD = {}
var save_paths_list = []
var path_opened = []
var pass_input_to_point = null
var event_last_position
var last_path_index = -1

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# OTHER
# ------------------------------------------------------------------------------

func _ready() -> void:
	# Set window size
	rect_size = Vector2(1288, 960)
	var screen_size = OS.get_screen_size()
	var window_size = rect_size
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, window_size)
	OS.set_window_size(window_size)
	OS.set_window_position(screen_size*0.5 - window_size*0.5)
	OS.set_window_always_on_top(true)

	update_style_for_input_and_text_boxes(self)
	
	create_input_maps()
	
	dialog_move_x_spinbox.get_line_edit().connect("focus_entered", self, "_on_x_SpinBox_focus_entered")
	dialog_move_y_spinbox.get_line_edit().connect("focus_entered", self, "_on_y_SpinBox_focus_entered")
	rotate_spinBox.get_line_edit().connect("focus_entered", self, "_on_rotate_SpinBox_focus_entered")
	scale_spinBox.get_line_edit().connect("gui_input", self, "_on_scale_spinbox_gui_input")

	connect_signals()
	get_config()

func get_config():
	var file = File.new()
	var config_file_path = "res://addons/pathedit/config"
	if file.file_exists(config_file_path):
		if file.open(config_file_path, File.READ) == 0:
			var _data = parse_json(file.get_line())
			var _id
			if _data is Dictionary:
				_id = "default_path"
				if _data.has(_id):
					save_paths_LineEdit.text = _data[_id]
				_id = "path_line_color"
				if _data.has(_id):
					path_line_color = Color(_data[_id])
					path_color.color = path_line_color
					
				_id = "canvas_clip_content"
				if _data.has(_id):
					canvas_clip_contents_CheckBox.pressed = _data[_id]
					canvas.rect_clip_content = !_data[_id]
				_id = "anchor_mode_selected"
				if _data.has(_id):
					mirror_option.select(_data[_id])
				_id = "animation_duration"
				if _data.has(_id):
					animation_duration.value = _data[_id]
			file.close()

func save_config():
	var file = File.new()
	var config_file_path = "res://addons/pathedit/config"
	if file.open(config_file_path, File.WRITE) == 0:
		var _data = {
			"default_path" 			: save_paths_LineEdit.text,
			"path_line_color"		: path_color.color.to_html(),
			"canvas_clip_content"	: canvas_clip_contents_CheckBox.pressed,
			"anchor_mode_selected"	: mirror_option.selected,
			"animation_duration"	: animation_duration.value
		}
		file.store_line(to_json(_data))
		file.close()

func connect_signals():
	if !canvas.is_connected("gui_input", self, "_on_Canvas_gui_input"):
		canvas.connect("gui_input", self, "_on_Canvas_gui_input")

func create_input_maps():
	var action_name = "CTRL + C"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_C], false, true, false)
	action_name = "CTRL + V"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_V], false, true, false)
	action_name = "ui_accept"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_ENTER, KEY_KP_ENTER], false, true, false)
	action_name = "CTRL + ALT + Z"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_Z], false, true, true)
	action_name = "CTRL + Z"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_Z], false, true, false)
	action_name = "CTRL + D"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_D], false, true, false)
	action_name = "SUPR"
	if !InputMap.has_action(action_name):
		create_input(action_name, [KEY_DELETE], false, false, false)

func create_input(action_name, keys, _shift = false, _control = false, _alt = false):
	InputMap.add_action(action_name)
	for key in keys:
		var event = InputEventKey.new()
		event.scancode = key
		event.shift = _shift
		event.control = _control
		event.alt = _alt
		InputMap.action_add_event(action_name, event)

func update_style_for_input_and_text_boxes(obj):
	if obj == file_dialog: return
	var children = obj.get_children()
	for child in children:
		var line_edit = null
		if child.get_child_count() != 0:
			update_style_for_input_and_text_boxes(child)
		if child is LineEdit:
			line_edit = child
		elif child is SpinBox:
			line_edit = child.get_line_edit()
		if line_edit != null:
			line_edit.caret_blink = true
			line_edit.set("custom_colors/cursor_color", Color("12a108"))
			line_edit.set("custom_colors/font_color", Color.white)
			line_edit.set("custom_colors/font_color_selected", Color("ff9292"))

func _process(delta: float) -> void:
	if animation.points != null:
		animated_sprite.visible = true
		var index = clamp(round(animation_position.offset), 0, animation.points.size() - 1)
		var new_position = (
			animation.points[index] +
			canvas.rect_global_position) + mod_position
		# Rotate sprite with direction
		var rotation = animated_sprite.rotation
		animated_sprite.look_at(new_position)
		var current_animation_time = tween_rotate_animation.tell()
		tween_rotate_animation.remove(animated_sprite, "rotation")
		tween_rotate_animation.interpolate_property(animated_sprite, "rotation",
			rotation, animated_sprite.rotation, 0.5, Tween.EASE_IN, Tween.EASE_OUT)
		animated_sprite.global_position = new_position
		tween_rotate_animation.seek(current_animation_time)
		tween_rotate_animation.start()

func _on_play_forward_button_button_up() -> void:
	play_animation(false)

func _on_play_backward_button_button_up() -> void:
	play_animation(true)

func _on_stop_animation_button_button_up() -> void:
	stop_animation()

func stop_animation():
	if animation.points != null:
		animation.points = null
		animated_sprite.visible = false
		animation_total_points_label.text = ""
		tween_animation.remove(animation_position, "offset")
	stop_buton.disabled = true

func update_animation_data():
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	if animation.points != null:
		animation.points = curve.get_baked_points()
		if animation.points.size() < 2:
			stop_animation()
			return
		animation_total_points_label.text = "Animation total points: %s" % animation.points.size()
	if animation.points == null:
		stop_animation()
		return
	var _from; var _to;
	if !animation.reverse_mode:
		_from = 0
		_to = animation.points.size() - 1
	else:
		_from = animation.points.size() - 1
		_to = 0
	var current_animation_frame = tween_animation.tell()
	tween_animation.remove(animation_position, "offset")
	tween_animation.interpolate_property(animation_position, "offset",
			_from, _to, animation_duration.value, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
	tween_animation.seek(current_animation_frame)
	tween_animation.start()

func play_animation(reverse_mode):
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	animation.points = curve.get_baked_points()
	if animation.points.size() == 0:
		animation.points = null
		return
	animation_total_points_label.text = "Animation total points: %s" % animation.points.size()
	var _from; var _to;
	if !reverse_mode:
		_from = 0
		_to = animation.points.size() - 1
	else:
		_from = animation.points.size() - 1
		_to = 0
	animation.reverse_mode = reverse_mode
	var current_animation_frame = tween_animation.tell()
	tween_animation.remove(animation_position, "offset")
	tween_animation.interpolate_property(animation_position, "offset",
			_from, _to, animation_duration.value, Tween.TRANS_LINEAR, Tween.TRANS_LINEAR)
	tween_animation.seek(current_animation_frame)
	tween_animation.start()
	stop_buton.disabled = false

func _on_animation_time_SpinBox_value_changed(value: float) -> void:
	animation_duration.value = value
	update_animation_data()

func _on_backed_SpinBox_value_changed(value: float) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	curve.set_bake_interval(value)
	update_animation_data()

func _on_Timer_timeout() -> void:
	if !animation.reverse_mode:
		animation.current_frame += 1
		if animation.current_frame > animation.points.size() - 1:
			animation.current_frame = 0
	else:
		animation.current_frame -= 1
		if animation.current_frame < 0:
			animation.current_frame = animation.points.size() - 1	

func refill_and_draw_points():
	var selected_index_in_point_list = get_selected_index(point_list)
	fill_points_list()
	draw_points_for_current_path()
	update_curve_draw()
	update_animation_data()
	point_list.select(selected_index_in_point_list)
	point_list.ensure_current_is_visible()
	point_list.emit_signal("item_selected", selected_index_in_point_list)

func _on_center_points_option_button_mouse_entered() -> void:
	center_points_button.texture_normal = center_points_button.texture_hover

func _on_center_points_option_button_mouse_exited() -> void:
	center_points_button.texture_normal = center_points_button.texture_focused

func _on_load_background_button_button_up() -> void:
	dialog_layer.visible = true
	file_dialog.set_valid_files(["png"])
	file_dialog.set_title("Select an Image")
	file_dialog.allow_multiple_selection = false
	file_dialog.directory_mode = false
	file_dialog.show()

func _on_FileDialog_file_selected(path: String) -> void:
	path_background.texture = load(path)

func _on_CustomFileDialog_select_files(files_string_array) -> void:
	if files_string_array.size() != 0:
		if !file_dialog.allow_multiple_selection:
			if !file_dialog.directory_mode:
				path_background.texture = load(files_string_array[0])
			else:
				var path = files_string_array[0]
				if path.right(path.length() - 1) != "/":
					path += "/"
				save_paths_LineEdit.text = path
		else:
			var current_paths = []
			for _data in data:
				current_paths.append(_data.name)
			for file in files_string_array:
				var obj = load(file)
				var name = file.get_file().trim_suffix(".tres")
				if obj is Curve2D:
					if !current_paths.has(name):
						create_path(name, obj)
						path_opened.append(name)
					else:
						var index = 0
						for i in path_list.get_item_count():
							if path_list.get_item_text(i) == name:
								path_list.select(i)
								path_list.ensure_current_is_visible()
								path_list.emit_signal("item_selected", i)
								break

func _on_CustomFileDialog_hide() -> void:
	hide_all_dialogs()

func _on_path_color_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and !event.is_pressed():
		dialog_layer.visible = true
		color_picker.visible = true

func _on_color_color_changed(color: Color) -> void:
	path_line_color = color
	path_color.color = color
	update_curve_draw()

func mirror_current_path_to(_id: String) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length < 2: return
	# Create action undoRedo
	create_undo("Set Curve",
		"",
		{
			"path_index" 	: path_index,
			"curve"			: get_curve_points(curve)
		}
	)

	# save the current points:
	var current_points = get_curve_points(curve)
	# get new points
	var new_points
	var _rotation_angle = 0
	match _id:
		"left"		: # no use
			_rotation_angle = deg2rad(90)
			new_points = rotate_points(_rotation_angle, current_points.duplicate(true))
		"right"		:
			var _scale = Vector2(-1, 1)
			new_points = scale_points(_scale, current_points.duplicate(true))
		"top"		:
			var _scale = Vector2(1, -1)
			new_points = scale_points(_scale, current_points.duplicate(true))
		"bottom"	:
			_rotation_angle = deg2rad(-180) # no use
			new_points = rotate_points(_rotation_angle, current_points.duplicate(true))

	# move new points to the right position
	var point_origin = Vector2.ZERO
	match mirror_option.selected:
		0: # First to first
			point_origin = current_points[0].point
			point_origin = new_points[0].point - point_origin
		1: # First to Last
			point_origin = current_points[current_points.size() - 1].point
			point_origin = new_points[0].point - point_origin
		2: # Mid to Mid
			var _real_id = (current_points.size() / 2)
			point_origin = current_points[_real_id].point
			point_origin = new_points[_real_id].point - point_origin
		3: # Last to first
			point_origin = current_points[current_points.size() - 1].point
			point_origin = new_points[0].point - point_origin
		4: # Last to Last
			point_origin = current_points[current_points.size() - 1].point
			point_origin = new_points[new_points.size() - 1].point - point_origin
	for i in new_points.size():
		new_points[i].point -= point_origin

	# Concatenated current points with new points
	new_points.invert()
	current_points += new_points
	# remove duplicated points
	for i in range(1, current_points.size()-1):
		if i > current_points.size() - 2: break
		var i2 = i + 1
		if (current_points[i].point == current_points[i2].point and
			current_points[i].in == current_points[i2].in and
			current_points[i].out == current_points[i2].out):
			current_points.remove(i)
		else:
			i2 = i - 1
			if (current_points[i].point == current_points[i2].point and
				current_points[i].in == current_points[i2].in and
				current_points[i].out == current_points[i2].out):
				current_points.remove(i)
		
	# add new points to the curve
	curve.clear_points()
	for i in current_points.size():
		curve.add_point(current_points[i].point,
						current_points[i].in, current_points[i].out)
	# redraw curve
	refill_and_draw_points()

func save_all_paths() -> void:
	var dir := Directory.new()
	if !dir.dir_exists(save_paths_LineEdit.text):
		dir.make_dir_recursive(save_paths_LineEdit.text)
	overwrite_file_paths_itemlist.clear()
	for i in save_paths_list:
		var obj = data[i]
		var path = "%s%s.tres" % [save_paths_LineEdit.text, obj.name]
		if dir.file_exists(path) and path_opened.find(obj.name) == -1:
			overwrite_file_paths_itemlist.add_item(path)
		else:
			ResourceSaver.save(path, obj.curve)
			path_list.set_item_text(i, obj.name)
			path_opened.append(obj.name)
	save_paths_list.clear()
	if overwrite_file_paths_itemlist.get_item_count() > 0:
		dialog_layer.visible = true
		overwrite_file_paths_dialog.visible = true
		overwrite_dialog_ok_button.grab_focus()

func _on_select_path_button_button_up() -> void:
	dialog_layer.visible = true
	file_dialog.set_valid_files(["tres"])
	file_dialog.set_title("Select Curve/s")
	file_dialog.allow_multiple_selection = true
	file_dialog.directory_mode = false
	file_dialog.show()

func perform_undo(item) -> void:
	if item == null: return
	match item.id:
		"Create Point":
			var path_index = item.parameters.path_index
			var point_index = item.parameters.point_index
			var curve = data[path_index].curve
			# Create redo 
			create_redo("Delete Point",
				"",
				{
					"path_index" 	: path_index,
					"point_index" 	: point_index
				}
			)
			# perform current undo
			curve.add_point(item.parameters.position.point,
				item.parameters.position.in, item.parameters.position.out, point_index)
			UndoRedo.backup()
			_on_path_list_item_selected(path_index)
			UndoRedo.restore()
		"Delete Point":
			var path_index = item.parameters.path_index
			var point_index = item.parameters.point_index
			var curve = data[path_index].curve
			if path_index < 0 or point_index > curve.get_point_count() - 1:
				UndoRedo.clear()
				return
			# Create redo 
			create_redo("Create Point",
				"",
				{
					"path_index" 	: path_index,
					"point_index" 	: point_index,
					"position"		: {
						"point" : curve.get_point_position(point_index),
						"in"	: curve.get_point_in(point_index),
						"out"	: curve.get_point_out(point_index)
					}
				}
			)
			# perform current undo
			curve.remove_point(point_index)
			fix_point_ids()
			UndoRedo.backup()
			_on_path_list_item_selected(path_index)
			UndoRedo.restore()
		"Set Curve":
			# Create action undoRedo
			var curve = data[item.parameters.path_index].curve
			create_redo("Set Curve",
				"",
				{
					"path_index" 	: item.parameters.path_index,
					"curve"			: get_curve_points(curve)
				}
			)
			curve.clear_points()
			for p in item.parameters.curve:
				curve.add_point(p.point, p.in, p.out)
			UndoRedo.backup()
			_on_path_list_item_selected(item.parameters.path_index)
			UndoRedo.restore()
		"Move Point":
			var path_index = item.parameters.path_index
			var point_index = item.parameters.point_index
			var sub_index = item.parameters.sub_index
			var curve = data[path_index].curve
			curve.set_point_position(point_index, item.parameters.position.point)
			curve.set_point_in(point_index, item.parameters.position.in)
			curve.set_point_out(point_index, item.parameters.position.out)
			UndoRedo.backup()
			var index = point_index * 3 + sub_index
			_on_path_list_item_selected(item.parameters.path_index)
			_on_point_list_item_selected(index)
			_on_point_list_item_selected(index)
			UndoRedo.restore()

func perform_redo(item) -> void:
	if item == null: return
	match item.id:
		"Create Point":
			var path_index = item.parameters.path_index
			var point_index = item.parameters.point_index
			var curve = data[path_index].curve
			# Create undo 
			create_undo("Delete Point",
				"",
				{
					"path_index" 	: path_index,
					"point_index" 	: point_index
				},
				false
			)
			# perform current redo
			curve.add_point(item.parameters.position.point,
				item.parameters.position.in, item.parameters.position.out, point_index)
			UndoRedo.backup()
			_on_path_list_item_selected(path_index)
			UndoRedo.restore()
		"Delete Point":
			var path_index = item.parameters.path_index
			var point_index = item.parameters.point_index
			var curve = data[path_index].curve
			if path_index < 0 or point_index > curve.get_point_count() - 1:
				UndoRedo.clear()
				return
			# Create undo 
			create_undo("Create Point",
				"",
				{
					"path_index" 	: path_index,
					"point_index" 	: point_index,
					"position"		: {
						"point" : curve.get_point_position(point_index),
						"in"	: curve.get_point_in(point_index),
						"out"	: curve.get_point_out(point_index)
					}
				},
				false
			)
			# perform current redo
			curve.remove_point(point_index)
			fix_point_ids()
			UndoRedo.backup()
			_on_path_list_item_selected(path_index)
			UndoRedo.restore()
		"Set Curve":
			var curve = data[item.parameters.path_index].curve
			# Create action undoRedo
			create_undo("Set Curve",
				"",
				{
					"path_index" 	: item.parameters.path_index,
					"curve"			: get_curve_points(curve)
				}
			)
			curve.clear_points()
			for p in item.parameters.curve:
				curve.add_point(p.point, p.in, p.out)
			UndoRedo.backup()
			_on_path_list_item_selected(item.parameters.path_index)
			UndoRedo.restore()

func create_undo(id, real_id = "", parameters = {}, clear_redo = true):
	var item = UndoRedo.Command.new()
	item.id = id
	item.real_id = real_id
	for key in parameters:
		item.add_parameter(key, parameters[key])
	UndoRedo.add_item(item, clear_redo)
	var path_index = get_selected_index(path_list)
	if !save_paths_list.has(path_index):
		save_paths_list.append(path_index)
		path_list.set_item_text(path_index, data[path_index].name + " (*)")

func create_redo(id, real_id = "", parameters = {}):
	var item = UndoRedo.Command.new()
	item.id = id
	item.real_id = real_id
	for key in parameters:
		item.add_parameter(key, parameters[key])
	UndoRedo.add_item_redo(item)

func _on_copy_path_button_button_up() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	if curve.get_point_count() == 0: return
	CLIPBOARD["Path"] = curve.duplicate(true)
	paste_path_button.disabled = false

func _on_paste_path_button_button_up() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	if CLIPBOARD.has("Path"):
		# Create action undoRedo
		create_undo("Set Curve",
			hash(data[path_index].curve),
			{
				"path_index" 	: path_index,
				"curve"			: get_curve_points(data[path_index].curve)
			}
		)
		var curve = CLIPBOARD["Path"].duplicate(true)
		data[path_index].curve = curve
		UndoRedo.backup()
		_on_path_list_item_selected(path_index)
		UndoRedo.restore()

func _on_path_list_gui_input(event: InputEvent) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	if event.is_action_pressed("CTRL + C"):
		_on_copy_path_button_button_up()
	elif event.is_action_pressed("CTRL + V"):
		_on_paste_path_button_button_up()
	elif event.is_action_pressed("CTRL + D"):
		duplicate_current_path()
	elif event.is_action_pressed("SUPR"):
		show_delete_path_dialog()

func _on_copy_point_button_button_up(_id = null) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var point_index = get_selected_index(point_list)
	if point_index == -1: return
	var curve = data[path_index].curve
	var real_id = point_index / 3
	CLIPBOARD["Point"] = {
		"point"	: curve.get_point_position(real_id),
		"in"	: curve.get_point_in(real_id),
		"out"	: curve.get_point_out(real_id)
	}
	paste_point_button.disabled = false

func _on_paste_point_button_button_up(_id = null) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var point_index = get_selected_index(point_list)
	if point_index == -1: return
	if CLIPBOARD.has("Point"):
		# Create action undoRedo
		var curve = data[path_index].curve
		create_undo("Set Curve",
			hash(curve),
			{
				"path_index" 	: path_index,
				"curve"			: get_curve_points(curve)
			}
		)
		var real_id = point_index / 3
		curve.set_point_position(real_id, CLIPBOARD["Point"].point)
		curve.set_point_in(real_id, CLIPBOARD["Point"].in)
		curve.set_point_out(real_id, CLIPBOARD["Point"].out)
		UndoRedo.backup()
		_on_path_list_item_selected(path_index)
		_on_point_list_item_selected(point_index)
		UndoRedo.restore()

func _on_point_list_gui_input(event: InputEvent) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var point_index = get_selected_index(point_list)
	if point_index == -1: return
	if event.is_action_pressed("CTRL + C"):
		_on_copy_point_button_button_up()
	elif event.is_action_pressed("CTRL + V"):
		_on_paste_point_button_button_up()
	elif event.is_action_pressed("SUPR"):
		_on_delete_point_button_button_up()

func _on_x_SpinBox_focus_entered() -> void:
	dialog_move_x_spinbox.get_line_edit().select_all()
	var caret_position = dialog_move_x_spinbox.get_line_edit().text.length()
	dialog_move_x_spinbox.get_line_edit().caret_position = caret_position

func _on_y_SpinBox_focus_entered() -> void:
	dialog_move_y_spinbox.get_line_edit().select_all()
	var caret_position = dialog_move_y_spinbox.get_line_edit().text.length()
	dialog_move_y_spinbox.get_line_edit().caret_position = caret_position

func _on_rotate_SpinBox_focus_entered() -> void:
	rotate_spinBox.get_line_edit().select_all()
	var caret_position = rotate_spinBox.get_line_edit().text.length()
	rotate_spinBox.get_line_edit().caret_position = caret_position

func _on_scale_spinbox_gui_input(event : InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		scale_by_ok_button()

func _on_help_button_mouse_entered() -> void:
	help_info.visible = true

func _on_help_button_mouse_exited() -> void:
	help_info.visible = false

func _on_select_paths_dialog_button_button_up() -> void:
	show_select_path_folder_dialog()

func _on_save_paths_LineEdit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		show_select_path_folder_dialog()

func show_select_path_folder_dialog():
	dialog_layer.visible = true
	file_dialog.set_valid_files(["all"])
	file_dialog.set_title("Select Folder")
	file_dialog.allow_multiple_selection = false
	file_dialog.directory_mode = true
	file_dialog.set_initial_folder(save_paths_LineEdit.text)
	file_dialog.show()

func _on_canvas_clip_contents_button_button_up() -> void:
	canvas_clip_contents_CheckBox.pressed = !canvas_clip_contents_CheckBox.pressed
	canvas.rect_clip_content = !canvas_clip_contents_CheckBox.pressed

func _on_delete_selected_path_button_button_up() -> void:
	show_delete_path_dialog()

func show_delete_path_dialog():
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	
	dialog_layer.visible = true
	delete_path_dialog.visible = true
	delete_path_dialog_ok_button.grab_focus()

func delete_path_selected() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var obj = data[path_index]
	# Remove data from data
	data.remove(path_index)
	# remove path in path_list
	path_list.remove_item(path_index)
	# re-check witch paths need be saved
	save_paths_list.clear()
	for i in path_list.get_item_count():
		if path_list.get_item_text(i).find("*") != -1:
			save_paths_list.append(i)
	# Select a new current path
	var index = min(path_index, path_list.get_item_count() - 1)
	if index != -1:
		path_list.select(index)
		path_list.ensure_current_is_visible()
		_on_path_list_item_selected(index)
	else:
		fill_points_list()
		draw_points_for_current_path()
		update_curve_draw()
		point_x_spinbox.editable = false
		point_x_spinbox.value = 0
		point_y_spinbox.editable = false
		point_y_spinbox.value = 0
		copy_path_button.disabled = true
		copy_point_button.disabled = true
		paste_path_button.disabled = true
		paste_point_button.disabled = true
		duplicate_path_button.disabled = true
		deleted_path_button.disabled = true
		delete_point_button.disabled = true
	# Clear UndoRedo
	UndoRedo.clear()
	# Delete file if exists in HDD and obj.name is added to path_opened array
	index = path_opened.find(obj.name)
	if index != -1:
		var path_name = save_paths_LineEdit.text + obj.name + ".tres"
		var dir := Directory.new()
		if dir.file_exists(path_name):
			dir.remove(path_name)
		# delete path in path_opened if path_opened has obj.name
		path_opened.remove(index)
	# hide dialog
	hide_all_dialogs()
	# pass focus to path_list
	path_list.grab_focus()

func duplicate_current_path():
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	# Create a new path and set curve as duplicated of the current path selected
	var path_name = get_fix_name_for_paths(data[path_index].name)
	create_path(path_name)
	data[-1].curve = data[path_index].curve.duplicate(true)
	# Insert this new path in the right position
	var real_index = path_index + 1
	data.insert(real_index, data.pop_back())
	# fix ids in save_paths_list
	for i in range(0, save_paths_list.size()):
		if save_paths_list[i] >= real_index:
			save_paths_list[i] += 1
	save_paths_list.append(real_index)
	# Move last path in path_list to the right position and rename it
	path_list.move_item(data.size() - 1, real_index)
	path_list.set_item_text(real_index, data[real_index].name + " (*)")
	path_list.select(real_index)
	path_list.ensure_current_is_visible()
	path_list.emit_signal("item_selected", get_selected_index(path_list))

func _on_duplicate_path_button_button_up() -> void:
	duplicate_current_path()

func _on_overwrite_paths_ok_button_button_up() -> void:
	var ids = overwrite_file_paths_itemlist.get_selected_items()
	if ids.size() > 0:
		for id in ids:
			var obj = data[id]
			if !path_opened.has(obj.name):
				path_opened.append(obj.name)
				save_paths_list.append(id)
	if save_paths_list.size() > 0:
		save_all_paths()
	_on_replace_dialog_cancel_button_button_up()

func _on_replace_dialog_cancel_button_button_up() -> void:
	# re-check for paths that need to be saved
	for i in range(0, data.size()):
		if path_list.get_item_text(i).find("*") != -1:
			save_paths_list.append(i)
	hide_all_dialogs()

func _on_delete_point_button_button_up() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var _point_id = get_selected_index(point_list)
	if _point_id == -1: return
	_point_id = _point_id / 3
	var _sub_point_id = 0
	var _control_point = point_container.get_child(_point_id)
	delete_point_with_mouse(_point_id, _sub_point_id, _control_point)

func _on_PathEdit_tree_exiting() -> void:
	save_config()

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# LIST STUFF
# ------------------------------------------------------------------------------

func get_selected_index(list : ItemList) -> int:
	if list.get_item_count() > 0:
		var items = list.get_selected_items()
		if items.size() != 0:
			return items[0]
		else:
			return 0
	return -1

func _on_path_list_item_selected(index: int) -> void:
	UndoRedo.clear()
	copy_point_button.disabled = true
	paste_point_button.disabled = true
	_on_stop_animation_button_button_up()
	fill_points_list()
	draw_points_for_current_path()
	update_curve_draw()
	initialize_extra_controls_data()
	backed_spinbox.editable = index != -1
	backed_spinbox.value = data[index].curve.get_bake_interval()
	_on_point_list_item_selected(0 if point_list.get_item_count() != 0 else -1)

func initialize_extra_controls_data():
	extra_controls_data.last_position 	= null
	extra_controls_data.last_angle 		= null
	extra_controls_data.last_zoom 		= null

func _on_point_list_item_selected(index: int, _final_action := true) -> void:
	if point_container.get_child_count() == 0:
		return
	if index == -1:
		point_x_spinbox.value = 0
		point_y_spinbox.value = 0
		point_x_spinbox.editable = false
		point_y_spinbox.editable = false
		return
	if index == 1:
		var editable_flag = point_container.get_child(0).linked_point != null
		point_x_spinbox.editable = editable_flag
		point_y_spinbox.editable = editable_flag
	elif index >= point_list.get_item_count() - 3:
		var editable_flag = point_container.get_child(0).linked_point == null
		point_x_spinbox.editable = editable_flag
		if index == point_list.get_item_count() - 1:
			point_x_spinbox.editable = false
			point_y_spinbox.editable = false
		else:
			point_x_spinbox.editable = editable_flag
			point_y_spinbox.editable = editable_flag
	else:
		point_x_spinbox.editable = true
		point_y_spinbox.editable = true
	var point_info = get_current_point_info()
	can_update_values = false
	point_x_spinbox.value = point_info.point.x
	point_y_spinbox.value = point_info.point.y
	can_update_values = true
	if _final_action:
		select_point_with_mouse(index / 3, index % 3)

func fill_points_list(_select_initial = true):
	point_list.clear()
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	delete_point_button.disabled = curve_points_length == 0
	copy_point_button.disabled = curve_points_length == 0
	paste_point_button.disabled = curve_points_length == 0 or !CLIPBOARD.has("Point")
	if (curve_points_length > 2 and
		curve.get_point_position(0) ==
		curve.get_point_position(curve_points_length - 1)):
		current_path_is_closed = true
	else:
		current_path_is_closed = false
	for i in range(0, curve_points_length):
		var _point	= curve.get_point_position(i)
		var _in		= curve.get_point_in(i)
		var _out	= curve.get_point_out(i)
		if current_path_is_closed and i == curve_points_length - 1:
			point_list.add_item("⬤Point %s * Linked to Point 1 * " % (i + 1))
			point_list.add_item("⬤  - in ")
			point_list.add_item("⬤  - out ")
		else:
			var str_point = "(%d, %d) " % [_point.x, _point.y]
			point_list.add_item("⬤Point %s %s" % [i + 1, str_point])
			str_point = "(%d, %d) " % [_in.x, _in.y]
			point_list.add_item("  - in %s" % str_point)
			str_point = "(%d, %d) " % [_out.x, _out.y]
			point_list.add_item("  - out %s" % str_point)
	if _select_initial:
		if point_list.get_item_count() > 0:
			point_list.select(0)
			point_list.ensure_current_is_visible()
			point_list.emit_signal("item_selected", 0)
		else:
			point_list.emit_signal("item_selected", -1)

func draw_points_for_current_path():
	# delete previous points
	for child in point_container.get_children():
		child.queue_free()
		point_container.remove_child(child)
	# initialize button close_path and close_path_button_label
	current_path_is_closed = false
	close_path_button_label.text = "CLOSE PATH"
	close_path_button.modulate = Color("ffffff")
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	# get curve
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	# create points for this curve
	for i in range(0, curve_points_length):
		var _point	= curve.get_point_position(i)
		var new_point = create_point(_point + canvas.rect_global_position + mod_position)
		var bound = "none"
		if i == 0: bound = "top_left"
		elif i == curve_points_length - 1: bound = "top_right"
		point_container.add_child(new_point)
		new_point.set_id(i, bound, curve_points_length)
		new_point.set_in_position(curve.get_point_in(i))
		new_point.set_out_position(curve.get_point_out(i))
		new_point.show_control_points(true, true)
		if (curve_points_length > 2 and
			i == curve_points_length - 1 and
			curve.get_point_position(0) == curve.get_point_position(i)):
			point_container.get_child(0).set_linked_point(new_point)
			current_path_is_closed = true
			close_path_button_label.text = "OPEN PATH"
			close_path_button.modulate = Color("0aeb1d")
		if i == curve_points_length - 1:
			set_point_list_item_name(i, 0)
			set_point_list_item_name(i, 1)
			set_point_list_item_name(i, 2)

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# UPDATE POINT STUFF
# ------------------------------------------------------------------------------

func set_point_list_item_name(_index, _sub_index):
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var point; var new_point_name;
	if _sub_index == 0:
		if current_path_is_closed and _index == curve.get_point_count() - 1:
			new_point_name = "⬤Point %s * Linked to Point 1 * " % (_index + 1)
		else:
			point = curve.get_point_position(_index)
			var str_point = "(%d, %d) " % [point.x, point.y]
			new_point_name = "⬤Point %s %s " % [_index + 1, str_point]
	elif _sub_index == 1:
		if current_path_is_closed and _index == curve.get_point_count() - 1:
			new_point_name = "  - in "
		else:
			point = curve.get_point_in(_index)
			var str_point = "(%d, %d) " % [point.x, point.y]
			new_point_name = "  - in %s " % str_point
	else:
		if current_path_is_closed and _index == curve.get_point_count() - 1:
			new_point_name = "  - out "
		else:
			point = curve.get_point_out(_index)
			var str_point = "(%d, %d) " % [point.x, point.y]
			new_point_name = "  - out %s " % str_point
	point_list.set_item_text(_index * 3 + _sub_index, new_point_name)

func get_current_point_info() -> Dictionary:
	var index = get_selected_index(point_list)
	var curve = data[get_selected_index(path_list)].curve
	var real_index = index / 3
	var sub_index = index % 3
	var point
	if sub_index == 0:
		point = curve.get_point_position(real_index)
	elif sub_index == 1:
		point = curve.get_point_in(real_index)
	else:
		point = curve.get_point_out(real_index)
	var point_info = {
		"list_selected_index"	: index,
		"real_index"			: real_index,
		"sub_index"				: sub_index,
		"curve"					: curve,
		"point"					: point
	}
	return point_info

func _on_x_SpinBox_value_changed(value: float) -> void:
	if can_update_values:
		update_point_selected(point_x_spinbox.value, point_y_spinbox.value)
		update_curve_draw()
		point_x_spinbox.release_focus()

func _on_y_SpinBox_value_changed(value: float) -> void:
	if can_update_values:
		update_point_selected(point_x_spinbox.value, point_y_spinbox.value)
		update_curve_draw()
		point_y_spinbox.release_focus()

func update_point_selected(x, y):
	# get curve and point selected
	var path_index = get_selected_index(path_list)
	var point_index = get_selected_index(point_list)
	if path_index == -1 or point_index == -1: return
	var point = Vector2(x, y)
	var curve = data[path_index].curve
	var real_index = point_index / 3
	var sub_index = point_index % 3
	# Create undo 
	create_undo("Move Point",
		hash(point_container.get_child(real_index)),
		{
			"path_index" 	: path_index,
			"point_index" 	: real_index,
			"sub_index" 	: sub_index,
			"position" 		: {
				"point" : curve.get_point_position(real_index),
				"in"	: curve.get_point_in(real_index),
				"out"	: curve.get_point_out(real_index)
			}
		}
	)
	# update point position in curve
	if sub_index == 0:
		curve.set_point_position(real_index, point)
	elif sub_index == 1:
		curve.set_point_in(real_index, point)
	else:
		curve.set_point_out(real_index, point)
	# update position of point drawn in screen:
	if sub_index == 0: point += canvas.rect_global_position
	for child in point_container.get_children():
		if child.id == real_index:
			if sub_index != 0: child.linked_control_points = false
			child.update_position(sub_index, point)
			child.show_control_points(true)
	# Change item text in point list for the item selected
	set_point_list_item_name(real_index, sub_index)
	update_animation_data()
	point_container.get_child(real_index).grab_focus()

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# CREATE PATH
# ------------------------------------------------------------------------------

func create_path(path_name : String, curve = Curve2D.new()) -> void:
	var new_path = {
		"name"	: path_name,
		"curve"	: curve
	}
	data.append(new_path)
	path_list.add_item(path_name)
	path_list.select(path_list.get_item_count() - 1)
	path_list.ensure_current_is_visible()
	path_list.emit_signal("item_selected", get_selected_index(path_list))
	path_list.grab_focus()
	copy_path_button.disabled = false
	duplicate_path_button.disabled = false
	deleted_path_button.disabled = false
	if CLIPBOARD.has("Path"):
		paste_path_button.disabled = false
	backed_spinbox.value = curve.bake_interval

func _on_add_new_path_button_button_up() -> void:
	dialog_layer.visible = true
	create_path_dialog.visible = true
	create_path_text.text = ""
	create_path_text.grab_focus()

func create_path_by_ok_button() -> void:
	var text = create_path_text.text.strip_edges()
	if text == "":
		text = "New path"
	var path_name = get_fix_name_for_paths(text)
	create_path(path_name)
	hide_all_dialogs()
	var path_index = data.size() - 1
	path_list.set_item_text(path_index, data[path_index].name + " (*)")
	save_paths_list.append(path_index)

func create_path_by_enter_key(text: String) -> void:
	text = text.strip_edges()
	if text == "":
		text = "New path"
	var path_name = get_fix_name_for_paths(text)
	create_path(path_name)
	hide_all_dialogs()
	var path_index = data.size() - 1
	path_list.set_item_text(path_index, data[path_index].name + " (*)")
	save_paths_list.append(path_index)

func get_fix_name_for_paths(text : String) -> String:
	text = text.replace(" ", "_")
	text = text.lstrip("_")
	text = text.rstrip("_")
	var illegal = ["<",">",":","\"","/","\\","|","?","*"]
	for _char in illegal: text = text.replace(_char, "")
	text = get_path_name(text)
	return text

func get_path_name(text : String) -> String:
	var n = 2
	var duplicated = true
	var new_text = text
	var regex = RegEx.new()
	regex.compile("(.*_)(\\d+)$")
	while duplicated:
		duplicated = false
		for _data in data:
			if _data.name == new_text:
				var result = regex.search(new_text)
				if result:
					n = int(result.get_strings()[2]) + 1
					new_text = "%s%s" % [result.get_strings()[1], n]
				else:
					new_text = "%s_%s" % [text, n]
					n += 1
				duplicated = true
				break
				
	return new_text

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# CANVAS STUFF
# ------------------------------------------------------------------------------

func get_curve_points(curve):
	var points = []
	for i in curve.get_point_count():
		var _points = {
			"point"	: curve.get_point_position(i),
			"in"	: curve.get_point_in(i),
			"out"	: curve.get_point_out(i)
		}
		points.append(_points)
	return points

func _on_ClosePath_button_button_up() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_size = curve.get_point_count()
	if curve_points_size < 3: return
	# Create action undoRedo
	create_undo("Set Curve",
		"",
		{
			"path_index" 	: path_index,
			"curve"			: get_curve_points(curve)
		}
	)
	if current_path_is_closed:
		# Open current curve
		var children = point_container.get_children()
		var _control_point = children[0].linked_point
		children[0].remove_linked_point()
		children[0].set_in_position(Vector2.ZERO)
		delete_point_with_mouse(children.size() - 1, 0, _control_point)
		children.pop_back()
		for i in range(1, children.size() - 1):
			children[i].set_visibility_for_control_points(true, true)
		children[children.size() - 1].set_visibility_for_control_points(true, false)
		children[0].set_visibility_for_control_points(false, true)
		current_path_is_closed = false
		close_path_button_label.text = "CLOSE PATH"
		close_path_button.modulate = Color("ffffff")
	else:
		# close current curve
		current_path_is_closed = true
		close_path_button_label.text = "OPEN PATH"
		close_path_button.modulate = Color("0aeb1d")
		# create point
		var index = point_list.get_item_count()
		var new_point = create_point(Vector2.ZERO)
		point_container.add_child(new_point)
		# add new item to the point_list
		point_list.add_item("⬤Point %s * Linked to Point 1 * " % (point_list.get_item_count() / 3 + 1))
		point_list.add_item("⬤  - in ")
		point_list.add_item("⬤  - out ")
		# add point to current curve
		var point = new_point.rect_global_position - canvas.rect_global_position
		# insert point at the end
		curve.add_point(point)
		# Set id for the point created
		new_point.set_id(index / 3, "top_right", curve.get_point_count())
		# link this point to point[0] in curve
		point_container.get_child(0).set_linked_point(new_point)
		# select point in point list (Select point[0])
		point_list.select(0)
		point_list.ensure_current_is_visible()
		point_list.emit_signal("item_selected", 0)
		# update visivility for control points in all points created
		var children = point_container.get_children()
		for i in range(0, children.size() - 1):
			children[i].set_visibility_for_control_points(true, true)
	# select the point created (Select point[0])
	select_point_with_mouse(0, 0)
	# update curve
	update_curve_draw()

func create_point(_position : Vector2) -> TextureRect:
	var new_point = control_point.instance()
	new_point.rect_global_position = _position - new_point.mod_position
	new_point.connect("position_changed", self, "move_point_with_mouse")
	new_point.connect("selected", self, "select_point_with_mouse")
	new_point.connect("deleted", self, "delete_point_with_mouse")
	new_point.connect("under_cursor", self, "delete_closest_point")
	new_point.connect("copied", self, "_on_copy_point_button_button_up")
	new_point.connect("pasted", self, "_on_paste_point_button_button_up")
	copy_point_button.disabled = false
	delete_point_button.disabled = false
	if CLIPBOARD.has("Point"):
		paste_point_button.disabled = false
	return new_point

func _on_Canvas_gui_input(event: InputEvent) -> void:
	if pass_input_to_point != null:
		if event is InputEventMouseMotion:
			event.position = get_global_mouse_position() - event_last_position + pass_input_to_point.mod_position
			event_last_position = get_global_mouse_position()
			pass_input_to_point._on_ControlPoint_gui_input(event)
		elif (event is InputEventMouseButton and event.button_index == 1 and
			!event.pressed):
			pass_input_to_point.drag = false
			pass_input_to_point = null
		return
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		var path_index = get_selected_index(path_list)
		if path_index == -1: return
		# if point_container has childs, path is closet
		# and closest_point == null, do not nothing
		if (closest_point == null and current_path_is_closed):
			return
		# create point
		var new_point = create_point(event.global_position)
		point_container.add_child(new_point)
		# add point to current curve
		var point = new_point.rect_global_position - canvas.rect_global_position
		var curve = data[path_index].curve
		# add point to point list
		var index
		if closest_point != null:
			# insert point beetween 2 points 
			var offset = curve.get_closest_offset(closest_point)
			index = get_curve_point_index_from_offset(curve, offset)
			# if path is closet and index == curve points size, set index - 1
			if (current_path_is_closed and index == curve.get_point_count()):
				index -= 1
			# move point in tree at right position
			point_container.move_child(new_point, index)
			curve.add_point(point, Vector2.ZERO, Vector2.ZERO, index)
			# fix point ids:
			fix_point_ids()
			# Create action undoRedo
			create_undo("Delete Point",
				"",
				{
					"path_index" 	: path_index,
					"point_index" 	: index
				}
			)
			# set real index in point list
			index *= 3
		else:
			# insert point at the end
			curve.add_point(point)
			index = point_list.get_item_count()
			# update old points ids
			var max_points = point_container.get_child_count()
			for child in point_container.get_children():
				child.set_id(child.id, child.bound, max_points)
			# Set id for the point created
			new_point.set_id(index / 3, "top_right", curve.get_point_count())
			# add new item to the point_list
			var str_point = "(%d, %d) " % [point.x, point.y]
			point_list.add_item("⬤Point %s %s" % [point_list.get_item_count() / 3 + 1, str_point])
			point_list.add_item("⬤  - in (0, 0) ")
			point_list.add_item("⬤  - out (0, 0) ")
			# Create action undoRedo
			create_undo("Delete Point",
				"",
				{
					"path_index" 	: path_index,
					"point_index" 	: curve.get_point_count() - 1
				}
			)
		# select point in point list
		point_list.select(index)
		point_list.ensure_current_is_visible()
		point_list.emit_signal("item_selected", index)
		pass_input_to_point = new_point
		pass_input_to_point.drag = true
		event_last_position = get_global_mouse_position()
		# update visivility for control points in all points created
		var children = point_container.get_children()
		# if path_is_closet, enable all controls point, else, disable first and last
		if current_path_is_closed:
			for i in range(0, children.size() - 1):
				children[i].set_visibility_for_control_points(true, true)
		else:
			for i in range(1, children.size() - 1):
				children[i].set_visibility_for_control_points(true, true)
			children[children.size() - 1].set_visibility_for_control_points(true, false)
			children[0].set_visibility_for_control_points(false, true)
		# select the point created
		select_point_with_mouse(index / 3, index % 3)
		# update curve
		update_curve_draw()
		# update animation data
		update_animation_data()
	elif event is InputEventMouseMotion:
		var index = get_selected_index(path_list)
		if index == -1: return
		var curve = data[index].curve
		var curve_point_length = curve.get_point_count()
		if index != -1 and curve_point_length > 1:
			var distance_info = {
				"distance"		: INF,
				"point"			: Vector2.ZERO
			}
			var _mouse_pos = get_global_mouse_position() - canvas.rect_global_position - mod_position
			var closest = curve.get_closest_point(_mouse_pos)
			var distance = _mouse_pos.distance_to(closest)
			if distance < distance_info.distance and distance < 8:
				distance_info.distance = distance
				distance_info.point = closest
			if distance_info.point != Vector2.ZERO:
				closest_point = distance_info.point
				canvas_layer1.update()
				distance_info = null
#				var warp_position = (
#					closest_point - _mouse_pos
#					if _mouse_pos.x > closest_point.x
#					else
#					_mouse_pos - closest_point
#				)
#				warp_mouse(get_global_mouse_position() + warp_position)
			else:
				closest_point = null
				canvas_layer1.update()

func fix_point_ids():
	var children = point_container.get_children()
	for i in range(0, children.size()):
		var bound = "none"
		if i == 0: bound = "top_left"
		elif i == children.size() - 1: bound = "top_right"
		children[i].set_id(i, bound, children.size())
	# refill point_list
	fill_points_list(false)

func get_curve_point_index_from_offset(curve, offset):
	var curve_point_length = curve.get_point_count()
	if curve_point_length < 2: return curve_point_length
	for i in range(1, curve.get_point_count()):
		var current_point_offset = curve.get_closest_offset(curve.get_point_position(i))
		if current_point_offset > offset: return i
	return curve_point_length

func select_point_with_mouse(_point_id, _sub_point_id):
	# Deselect other points
	var points = point_container.get_children()
	for point in points:
		if point.id != _point_id and point.selected: point.select(false)
		elif point.id == _point_id: point.select(true)
	# Select point in point_list
	var real_index = _point_id * 3 + _sub_point_id
	point_list.select(real_index)
	point_list.ensure_current_is_visible()
	_on_point_list_item_selected(real_index, false)
	
func move_point_with_mouse(_point_id, _sub_point_id, _position, _create_undo = true):
	# update point in curve
	var path_index = get_selected_index(path_list)
	var curve = data[path_index].curve
	# Create undo
	if _create_undo:
		create_undo("Move Point",
			str(hash(point_container.get_child(_point_id))) + str(_sub_point_id),
			{
				"path_index" 	: path_index,
				"point_index" 	: _point_id,
				"sub_index" 	: _sub_point_id,
				"position" 		: {
					"point" : curve.get_point_position(_point_id),
					"in"	: curve.get_point_in(_point_id),
					"out"	: curve.get_point_out(_point_id)
				}
			}
		)
	if _sub_point_id == 0:
		_position -= canvas.rect_global_position
		curve.set_point_position(_point_id, _position)
	elif _sub_point_id == 1:
		curve.set_point_in(_point_id, _position)
	else:
		curve.set_point_out(_point_id, _position)
	# update name in point_list
	set_point_list_item_name(_point_id, _sub_point_id)
	# update values in spinbox
	can_update_values = false
	point_x_spinbox.value = _position.x
	point_y_spinbox.value = _position.y
	can_update_values = true
	update_curve_draw()
	update_animation_data()
	
func delete_point_with_mouse(_point_id, _sub_point_id, _control_point):
	var index = _point_id * 3 + _sub_point_id
	var path_index = get_selected_index(path_list)
	var curve = data[path_index].curve
	if _sub_point_id == 0: # delete point
		create_undo("Create Point",
			"",
			{
				"path_index" 	: path_index,
				"point_index" 	: _point_id,
				"position"		: {
					"point"	: curve.get_point_position(_point_id),
					"in"	: curve.get_point_in(_point_id),
					"out"	: curve.get_point_out(_point_id),
				}
			}
		)
		if (_control_point.linked_point != null):
			current_path_is_closed = false
			close_path_button_label.text = "CLOSE PATH"
			close_path_button.modulate = Color("ffffff")
		curve.remove_point(_point_id)
		point_container.remove_child(_control_point)
		_control_point.queue_free()
		if point_container.get_child_count() < 4:
			current_path_is_closed = false
			close_path_button_label.text = "CLOSE PATH"
			close_path_button.modulate = Color("ffffff")
			if point_container.get_child_count() != 0:
				if point_container.get_child(0).linked_point != null:
					_control_point = point_container.get_child(0).linked_point
					point_container.get_child(0).remove_linked_point()
					curve.remove_point(point_container.get_child_count() - 1)
					point_container.remove_child(_control_point)
					_control_point.queue_free()
		fix_point_ids()
		index = min(_point_id * 3, point_list.get_item_count() - 1)
		if index != -1:
			_on_point_list_item_selected(index)
	elif _sub_point_id == 1: # reset point in to (0, 0)
		create_undo("Move Point",
			str(hash(point_container.get_child(_point_id))) + str(_sub_point_id),
			{
				"path_index" 	: path_index,
				"point_index" 	: _point_id,
				"sub_index" 	: _sub_point_id,
				"position" 		: {
					"point" : curve.get_point_position(_point_id),
					"in"	: curve.get_point_in(_point_id),
					"out"	: curve.get_point_out(_point_id)
				}
			}
		)
		curve.set_point_in(_point_id, Vector2.ZERO)
		_control_point.set_in_position(Vector2.ZERO)
		set_point_list_item_name(_point_id, _sub_point_id)
	elif _sub_point_id == 2: # reset point out to (0, 0)
		create_undo("Move Point",
			str(hash(point_container.get_child(_point_id))) + str(_sub_point_id),
			{
				"path_index" 	: path_index,
				"point_index" 	: _point_id,
				"sub_index" 	: _sub_point_id,
				"position" 		: {
					"point" : curve.get_point_position(_point_id),
					"in"	: curve.get_point_in(_point_id),
					"out"	: curve.get_point_out(_point_id)
				}
			}
		)
		curve.set_point_out(_point_id, Vector2.ZERO)
		_control_point.set_out_position(Vector2.ZERO)
		set_point_list_item_name(_point_id, _sub_point_id)
		pass
	canvas_layer0.update()
	update_animation_data()
	
	if curve.get_point_count() == 0:
		point_x_spinbox.value = 0
		point_y_spinbox.value = 0
		point_x_spinbox.editable = false
		point_y_spinbox.editable = false
		delete_point_button.disabled = true
		
	point_list.grab_focus()

func delete_closest_point():
	closest_point = null
	canvas_layer1.update()

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# DRAW STUFF
# ------------------------------------------------------------------------------

func update_curve_draw():
	canvas_layer0.update()
	closest_point = null
	canvas_layer1.update()
	
func _on_canvas_Layer0_draw() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length < 2: return
	var points = curve.get_baked_points()
	canvas_layer0.draw_set_transform(mod_position, 0, Vector2.ONE)
	#canvas_layer0.draw_multiline(points, Color.red)
	for i in range(0, points.size()- 1):
		var point1 = points[i]
		var point2 = points[i+1]
		canvas_layer0.draw_line(point1, point2, path_line_color, 3)

func _on_Layer1_draw() -> void:
	if closest_point != null:
		canvas_layer1.draw_circle(closest_point + mod_position, 6, Color.black)
		canvas_layer1.draw_circle(closest_point + mod_position, 4, path_line_color.contrasted())

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# ROTATE POINTS
# ------------------------------------------------------------------------------

func _on_rotate_points_Slider_value_changed(angle: float) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	rotate_points_by(angle, curve, curve_points_length)

func rotate_points_by(angle, curve, curve_points_length):
	var path_index = get_selected_index(path_list)
	# Create action undoRedo
	create_undo("Set Curve",
		hash(curve),
		{
			"path_index" 	: path_index,
			"curve"			: get_curve_points(curve)
		}
	)
	# rotate current points
	if extra_controls_data.last_angle == null:
		extra_controls_data.last_angle = angle
	else:
		if (angle > 0 and angle < abs(extra_controls_data.last_angle)):
			extra_controls_data.last_angle = angle
		elif (angle < 0 and abs(angle) < extra_controls_data.last_angle):
			extra_controls_data.last_angle = angle * PI
		else:
			extra_controls_data.last_angle = -angle
		angle = extra_controls_data.last_angle
	var center = get_points_center_from(curve, curve_points_length)
	angle = extra_controls_data.last_angle
	for i in range(0, curve_points_length):
		var point = curve.get_point_position(i)
		curve.set_point_position(i, rotate_point(center, angle, point))
		point = curve.get_point_in(i)
		curve.set_point_in(i, rotate_point(Vector2.ZERO, angle, point))
		point = curve.get_point_out(i)
		curve.set_point_out(i, rotate_point(Vector2.ZERO, angle, point))
	refill_and_draw_points()

func get_points_center_from(curve, curve_points_length):
	
	var x = 0; var y = 0; var area = 0; var k;
	var a = curve.get_point_position(curve_points_length - 1); var b = a;
	for i in range(0, curve_points_length):
		a = curve.get_point_position(i)
		k = a.y * b.x - a.x * b.y
		area += k
		x += (a.x + b.x) * k
		y += (a.y + b.y) * k
		b = a
	area *= 3
	if area == 0:
		if curve_points_length == 2:
			var mid_point = (curve.get_point_position(0) + curve.get_point_position(1)) * 0.5
			return mid_point
		return curve.get_point_position(0)
	else:
		return Vector2(x / area, y / area)

func get_center_from_points(points : Array) -> Vector2:
	var x = 0; var y = 0; var area = 0; var k;
	var points_length = points.size() - 1
	var a = points[points_length].point; var b = a;
	for i in range(0, points_length):
		a = points[i].point
		k = a.y * b.x - a.x * b.y
		area += k
		x += (a.x + b.x) * k
		y += (a.y + b.y) * k
		b = a
	area *= 3
	if area == 0:
		if points_length == 2:
			var mid_point = (points[0].point + points[1].point) * 0.5
			return mid_point
		return points[0].point
	else:
		return Vector2(x / area, y / area)

func rotate_points(angle : float, points : Array) -> Array:
	var center = get_center_from_points(points)
	for i in range(0, points.size()):
		points[i].point = rotate_point(center, angle, points[i].point)
		points[i].in = rotate_point(Vector2.ZERO, angle, points[i].in)
		points[i].out = rotate_point(Vector2.ZERO, angle, points[i].out)
	return points

func rotate_point(center, angle, point) -> Vector2:
	var clockwise = false
	if angle >= 0:
		clockwise = true
		angle = -angle
	var s = sin(angle)
	var c = cos(angle)
	# translate point back to origin
	point -= center
	# rotate point
	var new_point = point
	if clockwise:
		new_point = Vector2(
			point.x * c - point.y * s,
			point.x * s + point.y * c
		)
	else:
		new_point = Vector2(
			point.x * c + point.y * s,
			-point.x * s + point.y * c
		)
		
	# translate point back
	point = new_point + center
	return point

func _on_rotate_points_Slider_reset(_value) -> void:
	extra_controls_data.last_angle = null

func _on_rotate_points_Slider_dblClick() -> void:
	show_rotate_dialog()
	
func show_rotate_dialog():
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	
	dialog_layer.visible = true
	dialog_rotate.visible = true
	rotate_spinBox.value = 0
	rotate_spinBox.get_line_edit().grab_focus()

func rotate_by_ok_button() -> void:
	var _value = Vector2(-rotate_spinBox.value, 0)
	rotate_by_input_value(_value)

func rotate_by_input_value(_value) -> void:
	if !_value is Vector2:
		if Input.is_action_just_pressed("ui_accept"):
			rotate_by_ok_button()
		return
		
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	
	rotate_points_by(deg2rad(_value.x), curve, curve_points_length)
	hide_all_dialogs()

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# MOVE POINTS
# ------------------------------------------------------------------------------

func _on_move_vertical_Slider_value_changed(_value) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
		
	move_points_by(Vector2(0, _value), curve, curve_points_length)

func _on_move_horizontal_Slider_value_changed(_value) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
		
	move_points_by(Vector2(_value, 0), curve, curve_points_length)

func move_points_by(_value, curve, curve_points_length):
	var path_index = get_selected_index(path_list)
	# Create action undoRedo
	create_undo("Set Curve",
		hash(curve),
		{
			"path_index" 	: path_index,
			"curve"			: get_curve_points(curve)
		}
	)
	if (extra_controls_data.last_position == null or
		!extra_controls_data.last_position is Vector2):
		extra_controls_data.last_position = _value
	else:
		var current_value = _value
		_value = _value - extra_controls_data.last_position
		extra_controls_data.last_position = current_value
	for i in range(0, curve_points_length):
		var point = curve.get_point_position(i)
		curve.set_point_position(i, point + _value)
	refill_and_draw_points()

func _on_move_horizontal_Slider_reset(_value) -> void:
	extra_controls_data.last_position = _value

func _on_move_vertical_Slider_reset(_value) -> void:
	extra_controls_data.last_position = _value

func _on_move_vertical_Slider_dblClick() -> void:
	show_move_dialog("vertical")

func _on_move_horizontal_Slider_dblClick() -> void:
	show_move_dialog("horizontal")

func show_move_dialog(mode : String) -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	
	dialog_layer.visible = true
	dialog_move.visible = true
	var _position
	#dialog_move_selector
	if mode == "vertical":
		_position = Vector2(
			move_y_slider.rect_global_position.x -
				dialog_move.rect_size.x - 20,
			move_y_slider.rect_global_position.y +
				move_y_slider.rect_size.y * 0.5 - dialog_move.rect_size.y * 0.5
		)
		dialog_move_selector.position.x = (dialog_move.rect_size.x + 
			dialog_move_selector.texture.get_width() * 0.5 - 8)
		dialog_move_selector.position.y = dialog_move.rect_size.y * 0.5
		dialog_move_selector.scale = Vector2(1, 1)
		dialog_move_selector.rotation_degrees = 90
	else:
		_position = Vector2(
			move_x_slider.rect_global_position.x +
				move_x_slider.rect_size.x * 0.5 - dialog_move.rect_size.x * 0.5,
			move_x_slider.rect_global_position.y -
				dialog_move.rect_size.y - 20
		)
		dialog_move_selector.position.x = dialog_move.rect_size.x * 0.5
		dialog_move_selector.position.y = (dialog_move.rect_size.y + 
			dialog_move_selector.texture.get_height() * 0.5 - 8)
		dialog_move_selector.scale = Vector2(-1, -1)
		dialog_move_selector.rotation_degrees = 0
		
	dialog_move.rect_global_position = _position
	dialog_move_x_spinbox.value = 0
	dialog_move_y_spinbox.value = 0
	if mode == "vertical":
		dialog_move_y_spinbox.get_line_edit().grab_focus()
	else:
		dialog_move_x_spinbox.get_line_edit().grab_focus()

func move_by_ok_button() -> void:
	var value = Vector2(dialog_move_x_spinbox.value, dialog_move_y_spinbox.value)
	move_by_input_value(value)
	
func move_by_input_value(_value) -> void:
	if !_value is Vector2:
		if Input.is_action_just_pressed("ui_accept"):
			move_by_ok_button()
		return
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	var point_index = get_selected_index(point_list)
	move_points_by(_value, curve, curve_points_length)
	extra_controls_data.last_position = null
	hide_all_dialogs()

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# SCALE POINTS
# ------------------------------------------------------------------------------

func _on_scale_points_Slider_dblClick() -> void:
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length < 2: return
	
	dialog_layer.visible = true
	scale_dialog.visible = true
	scale_spinBox.value = 1
	scale_spinBox.get_line_edit().grab_focus()
	scale_spinBox.get_line_edit().select_all()
	scale_spinBox.get_line_edit().caret_position = 1

func scale_by_ok_button() -> void:
	var _value = Vector2(scale_spinBox.value, 0)
	scale_by_input_value(_value)

func scale_by_input_value(_value) -> void:
	if !_value is Vector2:
		if Input.is_action_just_pressed("ui_accept"):
			scale_by_ok_button()
		return
		
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	
	scale_points_by(_value.x, curve, curve_points_length)
	hide_all_dialogs()

func _on_scale_points_Slider_value_changed(_value) -> void:
	if _value == null: return
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length < 2: return
	
	if _value < 2.5:
		_value = get_real_value(0.2, 1, 0.2, 2.5, _value)
	else:
		_value = get_real_value(1, 5, 2.5, 5, _value)
	scale_label.text = "Scale points by %s" % _value

func _on_scale_points_Slider_reset(_value) -> void:
	if _value == null: return
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length < 2: return
	
	if scale_slider.get_current_value() == scale_slider.get_center_value():
		return
	
	if _value < 2.5:
		_value = get_real_value(0.2, 1, 0.2, 2.5, _value)
	else:
		_value = get_real_value(1, 5, 2.5, 5, _value)
		
	scale_points_by(abs(_value), curve, curve_points_length)
	scale_label.text = ""

func get_real_value(minOutput, maxOutput, minInput, maxInput, input):
	var output = ((input - minInput) / (maxInput - minInput) *
				(maxOutput - minOutput) + minOutput)
	return output

func scale_points_by(_value, curve, curve_points_length):
	var path_index = get_selected_index(path_list)
	# Create action undoRedo
	create_undo("Set Curve",
		hash(curve),
		{
			"path_index" 	: path_index,
			"curve"			: get_curve_points(curve)
		}
	)
	var center = get_points_center_from(curve, curve_points_length)
	var mid = Vector2.ZERO
	var mod = ((center * _value) - center)
	for i in range(0, curve_points_length):
		var point = curve.get_point_position(i)
		curve.set_point_position(i, point * _value - mod)
		point = curve.get_point_in(i)
		curve.set_point_in(i, point * _value)
		point = curve.get_point_out(i)
		curve.set_point_out(i, point * _value)
	refill_and_draw_points()

func scale_points(_value : Vector2, points : Array) -> Array:
	var center = get_center_from_points(points)
	var mod = ((center * _value) - center)
	for i in range(0, points.size()):
		points[i].point = points[i].point * _value - mod
		points[i].in = points[i].in * _value
		points[i].out = points[i].out * _value
		if _value.x < 0 or _value.y < 0:
			var point = points[i].in
			points[i].in = points[i].out
			points[i].out = point
	return points

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------



# ------------------------------------------------------------------------------
# MOVE POINTS WITH CENTER OPTION BUTTON
# ------------------------------------------------------------------------------
func _on_center_points_option_button_item_selected(id: int) -> void:
	if id == 0: return
	center_points_option_button.select(0)
	var path_index = get_selected_index(path_list)
	if path_index == -1: return
	var curve = data[path_index].curve
	var curve_points_length = curve.get_point_count()
	if curve_points_length == 0: return
	
	match id:
		1: # Anchor points to center of canvas
			# get center of canvas
			var canvas_center = canvas.rect_size * 0.5
			var points_center = get_points_center_from(curve, curve_points_length)
			var dest = points_center - canvas_center
			move_all_points_to(dest, curve, curve_points_length)
		2: # Anchor points to (0, 0)
			var point_origin = curve.get_point_position(0)
			move_all_points_to(point_origin, curve, curve_points_length)
		3: # Flip points Horizontally
			var value = Vector2(-1, 1)
			scale_points_by(value, curve, curve_points_length)
		4: # Flip points Vertically
			var value = Vector2(1, -1)
			scale_points_by(value, curve, curve_points_length)
		5: # Flip points Horizontally and Vertically
			var value = Vector2(-1, -1)
			scale_points_by(value, curve, curve_points_length)

func move_all_points_to(point_origin, curve, curve_points_length):
	var path_index = get_selected_index(path_list)
	# Create action undoRedo
	create_undo("Set Curve",
		hash(curve),
		{
			"path_index" 	: path_index,
			"curve"			: get_curve_points(curve)
		}
	)
	for i in range(0, curve_points_length):
		var point = curve.get_point_position(i)
		curve.set_point_position(i, point - point_origin)
	refill_and_draw_points()

func _on_hide_behind_controls_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		hide_all_dialogs()

func hide_all_dialogs():
	delete_path_dialog.visible = false
	create_path_dialog.visible = false
	dialog_move.visible = false
	dialog_rotate.visible = false
	scale_dialog.visible = false
	color_picker.visible = false
	dialog_layer.visible = false
	overwrite_file_paths_dialog.visible = false

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

