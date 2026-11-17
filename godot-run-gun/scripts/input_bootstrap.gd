extends Node

## Creates the project's default keyboard map so the demo works after opening it.
func _ready() -> void:
	_bind_key("move_left", KEY_A)
	_bind_key("move_left", KEY_LEFT)
	_bind_key("move_right", KEY_D)
	_bind_key("move_right", KEY_RIGHT)
	_bind_key("jump", KEY_SPACE)
	_bind_key("jump", KEY_W)
	_bind_key("crouch", KEY_S)
	_bind_key("crouch", KEY_DOWN)
	_bind_key("fire", KEY_J)
	_bind_key("melee", KEY_K)
	_bind_key("interact", KEY_E)
	_bind_key("aim_up", KEY_KP_8)
	_bind_key("aim_down", KEY_KP_5)
	_bind_key("aim_left", KEY_KP_4)
	_bind_key("aim_right", KEY_KP_6)

func _bind_key(action: StringName, code: Key) -> void:
	if not InputMap.has_action(action): InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = code
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and existing.physical_keycode == code: return
	InputMap.action_add_event(action, event)
