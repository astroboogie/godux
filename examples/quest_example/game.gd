# Attach this scene to a root scene node.

extends Node

onready var actions := get_node('/root/actions')
onready var reducers := get_node('/root/reducers')
onready var store := get_node('/root/store')

func _ready() -> void:
	store.create([
		{ 'name': 'game', 'instance': reducers },
		{ 'name': 'quests', 'instance': reducers },
	], [{'name': '_check_quests', 'instance': self}])
	
	store.subscribe(self, '_quest_completed')
	
	store.dispatch(actions.quests_create(
		"collect_coins1", "Collect 5 coins.", "coins", 5))
	
	store.dispatch(actions.quests_create(
		"collect_coins2", "Collect 8 coins.", "coins", 8))

func _quest_completed(name, difference):
	if name == 'quests':
		for quest_name in difference.keys():
			if difference[quest_name]['completed'] == true:
				var state = store.get_state()
				var description = state[name][quest_name]['description']
				print("COMPLETED: " + description)

func _check_quests(name, difference):
	if name == 'quests':
		return
	
	var state = store.get_state()
	for quest_name in state['quests'].keys():
		var quest = state['quests'][quest_name]
		if state['game'][quest['key']] == quest['amount']:
			store.dispatch(actions.quests_update(quest_name, true))
