extends Node


var UndoStack = []
var RedoStack = []
var _backup = {
	"UndoStack" : null,
	"RedoStack" : null
}
var CurrentItem = null

var ctrl_pressed = false
var alt_pressed = false

var MaxUndo = 100
var MaxRedo = 100

signal undoHappened(item)
signal redoHappened(item)

class Command:
	var real_id := ""
	var id := ""
	var parameters := {}
	
	func add_parameter(key, value):
		parameters[key] = value
		
	func to_s():
		var _data = ""
		for key in parameters:
			_data += "%s : %s, " % [key, parameters[key]]
		var text = "%s [%s]" % [id, _data]
		return text

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("CTRL + ALT + Z") and can_redo():
		redo()
	elif event.is_action_pressed("CTRL + Z") and can_undo():
		undo()
	return
#	if event is InputEventKey:
#		if event.scancode == KEY_CONTROL:
#			ctrl_pressed = event.is_pressed()
#		if event.scancode == KEY_ALT:
#			alt_pressed = event.is_pressed()
#
#		if event.scancode == KEY_Z and event.is_pressed():
#			if ctrl_pressed and alt_pressed and can_redo():
#				redo()
#			elif ctrl_pressed and can_undo():
#				undo()

func clear():
	UndoStack.clear()
	RedoStack.clear()
	CurrentItem = null
	
func clear_last_undo():
	UndoStack.pop_back()
	
func add_item(item : Command, clear_redo : bool = true):
	if (UndoStack.size() > 0 and UndoStack[UndoStack.size() - 1].id == item.id and
		item.real_id != "" and item.real_id == UndoStack[UndoStack.size() - 1].real_id):
		#UndoStack[UndoStack.size() - 1] = item
		return
	else:
		if UndoStack.size() == MaxUndo:
			UndoStack.pop_front()
		UndoStack.append(item)
	CurrentItem = item
	if clear_redo:
		RedoStack.clear()
	
func add_item_redo(item : Command):
	if RedoStack.size() == MaxRedo:
		RedoStack.pop_front()
	RedoStack.append(item)
		
func undo():
	#RedoStack.append(CurrentItem)
	CurrentItem = UndoStack.pop_back()
	emit_signal("undoHappened", CurrentItem)
	
func redo():
	#UndoStack.append(CurrentItem)
	CurrentItem = RedoStack.pop_back()
	emit_signal("redoHappened", CurrentItem)
	
func can_undo():
	return(UndoStack.size() != 0)
	
func can_redo():
	return(RedoStack.size() != 0)
	
func backup():
	_backup.RedoStack = RedoStack.duplicate()
	_backup.UndoStack = UndoStack.duplicate()
	
func restore():
	RedoStack = _backup.RedoStack.duplicate()
	UndoStack = _backup.UndoStack.duplicate()
	_backup.RedoStack = null
	_backup.UndoStack = null
