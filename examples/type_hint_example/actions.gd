# This is a singleton. Autoload it through "Scene > Project Settings > AutoLoad."

extends Node

onready var types := get_node('/root/action_types')

func game_set_start_time(time: int) -> Dictionary:
    return {
        'type': types.GAME_SET_START_TIME,
        'time': time
    }

func player_set_name(name: String) -> Dictionary:
    return {
        'type': types.PLAYER_SET_NAME,
        'name': name
    }

func player_set_health(health: int) -> Dictionary:
    return {
        'type': types.PLAYER_SET_HEALTH,
        'health': health
    }
