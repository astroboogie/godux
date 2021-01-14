# This is a singleton. Autoload it through "Scene > Project Settings > AutoLoad."

extends Node

onready var types := get_node('/root/action_types')

func game_add_coins(coins):
	return {
		'type': types.GAME_ADD_COINS,
		'coins': coins,
	}

func quests_create(name, description, key, amount):
	return {
		'type': types.QUESTS_CREATE,
		'name': name,
		'description': description,
		'key': key,
		'amount': amount,
	}

func quests_update(name, completed):
	return {
		'type': types.QUESTS_UPDATE,
		'name': name,
		'completed': completed,
	}
