extends Control

export(String, DIR)		var initial_folder				= "res//"
export(Array, String)	var valid_files					= ["png"]
export(bool)			var allow_multiple_selection 	= false
export(bool)			var directory_mode				= false

var last_position = null
var directory_history = []

var default_file = preload("CustomFile.tscn")

var default_icons = {
	"folder"		: preload("Graphics/folder.png"),
	"file"			: preload("Graphics/file.png"),
	"file_empty"	: preload("Graphics/file_empty.png"),
}

var process_file_stack = []
var max_child_added_by_ticks = 4
var drag = false

onready var window_title 					= $PanelTop/WindowTitle
onready var scroll_container 				= $PanelBottom/ScrollContainer
onready var Grid 							= $PanelBottom/ScrollContainer/VBoxContainer/Grid
onready var path_line_edit					= $PanelBottom/path_LineEdit
onready var file_line_edit					= $PanelBottom/file_LineEdit
onready var ok_button						= $PanelBottom/okButton
onready var back_button						= $PanelBottom/backButton
onready var hide_panel						= $hide_behind_controls
onready var create_folder_dialog			= $create_folder_dialog
onready var create_folder_dialog_lineedit	= $create_folder_dialog/LineEdit

signal select_files(files_string_array)

func _ready() -> void:
	Grid.rect_min_size = scroll_container.rect_size
	populate_files()
	
func _process(delta: float) -> void:
	if process_file_stack.size() > 0:
		var _to = min(max_child_added_by_ticks, process_file_stack.size())
		for i in _to:
			var file = process_file_stack.pop_front()
			var obj = default_file.instance()
			var _texture
			if file.is_directory:
				_texture = default_icons.folder
			elif file.extension.to_lower() == "png":
				_texture = load(file.full_path)
			else:
				_texture = default_icons.file
			obj.set_data(_texture, file)
			obj.directory_mode = directory_mode
			Grid.add_child(obj)
			obj.connect("change_directory", self, "change_directory")
			obj.connect("dblClick", self, "select_file_by_dblClick")
			obj.connect("selected", self, "select_file")
			

func change_directory(_path):
	directory_history.append(initial_folder)
	back_button.hint_tooltip = "Go To \"%s\"" % initial_folder
	initial_folder = _path + "/" if _path[_path.length() - 1] != "/" else _path
	populate_files()
	ok_button.grab_focus()

func select_file(_file):
	if directory_mode:
		allow_multiple_selection = false
	file_line_edit.text = ""
	var children = Grid.get_children()
	if !allow_multiple_selection:
		for child in children:
			if child.selected:
				if child.full_path != _file:
					child.set_selected(false)
				else:
					if !directory_mode:
						file_line_edit.text = child.label.text + " "
					else:
						var path = child.full_path
						if path.right(path.length() - 1) != "/":
							path += "/"
						path += " "
						file_line_edit.text = path
						
	else:
		var file_line_edit_text = ""
		for child in children:
			if child.selected:
				if file_line_edit_text.length() == 0:
					file_line_edit_text += child.label.text
				else:
					file_line_edit_text += ", %s" % child.label.text
		file_line_edit.text = file_line_edit_text + " "
	ok_button.grab_focus()

func populate_files():
	var dir := Directory.new()
	if !dir.dir_exists(initial_folder):
		initial_folder = "res://"
	var children = Grid.get_children()
	for child in children:
		Grid.remove_child(child)
		child.queue_free()
	process_file_stack.clear()
	list_files_in_directory(initial_folder)
	path_line_edit.text = initial_folder
	if !directory_mode:
		file_line_edit.text = ""
	else:
		file_line_edit.text = initial_folder

func move_window(event):
	if event is InputEventMouseMotion and drag:
		if last_position == null:
			last_position = event.position
		rect_global_position += event.position - last_position
	elif event is InputEventMouseButton and event.button_index == 1:
		if event.is_pressed():
			drag = true
		else:
			last_position = null
			drag = false
	ok_button.grab_focus()
	
func list_files_in_directory(path):
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if !dir.current_is_dir() and directory_mode:
				continue
			var current_is_dir = dir.current_is_dir()
			if (valid_files.size() == 0 or
				valid_files.find("all") != -1 or
				valid_files.find(file.get_extension()) != -1 or
				current_is_dir):
				var full_path = (path + file.get_basename() + "." +
					file.get_extension() if !current_is_dir else
					path + file.get_basename())
				var new_file = {
					"full_path" 		: full_path,
					"filename" 			: file.get_file(),
					"extension"			: file.get_extension(),
					"is_directory" 		: current_is_dir
				}
				process_file_stack.append(new_file)

	dir.list_dir_end()
	
func set_title(_title):
	window_title.text = str(_title)
	
func set_valid_files(arr_valid_file_extension):
	if arr_valid_file_extension is Array:
		valid_files = arr_valid_file_extension

func select_file_by_dblClick(_file):
	emit_signal("select_files", [_file.rstrip(" ").lstrip(" ")])
	hide()
	
func _on_backButton_button_up() -> void:
	# Go to last directory
	if directory_history.size() > 0:
		var _path = directory_history.pop_back()
		change_directory(_path)
		directory_history.pop_back()
		if directory_history.size() != 0:
			back_button.hint_tooltip = "Go To \"%s\"" % directory_history[-1]
		else:
			back_button.hint_tooltip = ""

func _on_okButton_button_down() -> void:
	# select current file/s
	var files = file_line_edit.text.split(", ")
	var paths = []
	var full_path
	for file in files:
		if !directory_mode:
			full_path = (initial_folder + file).rstrip(" ").lstrip(" ")
		else:
			full_path = file.rstrip(" ").lstrip(" ")
		paths.append(full_path)
	emit_signal("select_files", paths)
	hide()


func _on_CloseButton_button_up() -> void:
	hide()
	
func show():
	populate_files()
	.show()
	ok_button.grab_focus()



func _on_createDirectory_button_up() -> void:
	show_create_folder_dialog(true)
	create_folder_dialog_lineedit.text = ""
	create_folder_dialog_lineedit.grab_focus()
	create_folder_dialog_lineedit.select_all()


func _on_cancel_button_button_up() -> void:
	show_create_folder_dialog(false)


func _on_create_folder_ok_button_button_up() -> void:
	var text = create_folder_dialog_lineedit.text
	if text.length() != 0:
		# Create a new directory if no exists and go into it
		var path = initial_folder + create_folder_dialog_lineedit.text
		var dir := Directory.new()
		if !dir.dir_exists(path):
			dir.make_dir_recursive(path)
		yield(get_tree(), "idle_frame")
		change_directory(path)
	show_create_folder_dialog(false)


func _on_hide_behind_controls_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
		show_create_folder_dialog(false)
	
func show_create_folder_dialog(_value):
	hide_panel.visible = _value
	create_folder_dialog.visible = _value


func _on_LineEdit_text_entered(new_text: String) -> void:
	_on_create_folder_ok_button_button_up()
	
func set_initial_folder(path : String) -> void:
	if path.find("res://") != 0: return
	initial_folder = path
	change_directory(path)
	var history = path.right(6)
	history = history.left(history.length() - 1).split("/")
	if history.size() == 1:
		directory_history.append("res://")
		back_button.hint_tooltip = "Go To \"%s\"" % directory_history[-1]
	else:
		history.remove(history.size() - 1)
		directory_history.clear()
		while history.size() > 0:
			directory_history.append("res://" + history.join("/"))
			history.remove(history.size() - 1)
		if directory_history.size() != 0:
			directory_history.append("res://")
			directory_history.invert()
			back_button.hint_tooltip = "Go To \"%s\"" % directory_history[-1]
		else:
			back_button.hint_tooltip = ""
	
