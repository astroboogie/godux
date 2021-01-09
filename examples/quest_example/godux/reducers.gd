# This is a singleton. Autoload it through "Scene > Project Settings > AutoLoad."

extends Node

onready var types := get_node('/root/action_types')
onready var store := get_node('/root/store')

func game(state, action):
	if action['type'] == types.GAME_ADD_COINS:
		var next_state = store.shallow_copy(state)
		if 'coins' in next_state:
			next_state['coins'] += action['coins']
		else:
			next_state['coins'] = action['coins']
		return next_state

	return state

func quests(state, action):
	if action['type'] == types.QUESTS_CREATE:
		var next_state = store.shallow_copy(state)
		var quest_state = {
			'description': action['description'],
			'key': action['key'],
			'amount': action['amount'],
			'completed': false,
		}
		
		next_state[action['name']] = quest_state
		return next_state
	
	if action['type'] == types.QUESTS_UPDATE:
		var quest_state = store.shallow_copy(state[action['name']])
		quest_state['completed'] = action['completed']
		
		var new_state = store.shallow_copy(state)
		new_state[action['name']] = quest_state
		return new_state
	
	return state
