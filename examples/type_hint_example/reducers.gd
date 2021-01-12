# This is a singleton. Autoload it through "Scene > Project Settings > AutoLoad."

extends Node

onready var types := get_node('/root/action_types')
onready var store := get_node('/root/store')

func game(state: Dictionary, action: Dictionary) -> Dictionary:
    if action['type'] == types.GAME_SET_START_TIME:
        var next_state : Dictionary = state.duplicate()
        next_state['start_time'] = action['time']
        return next_state
    return state

func player(state: Dictionary, action: Dictionary) -> Dictionary:
    if action['type'] == types.PLAYER_SET_NAME:
        var next_state : Dictionary = state.duplicate()
        next_state['name'] = action['name']
        return next_state
    if action['type'] == types.PLAYER_SET_HEALTH:
        var next_state : Dictionary = state.duplicate()
        next_state['health'] = action['health']
        return next_state
    return state
