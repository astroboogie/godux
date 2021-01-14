# Attach this scene to a root scene node.

extends Node

onready var store := get_node('/root/store')
onready var watch := get_node('/root/watch')
onready var actions := get_node('/root/actions')
onready var reducers := get_node('/root/reducers')

func _ready() -> void:
	store.create([
		{ 'name': 'game', 'instance': reducers },
		{ 'name': 'quests', 'instance': reducers },
	])
	
	# Using "watch" subscribe enhancer - this lets us be notified
	# only when "game.coins" is updated
	watch.subscribe(self, 'coins_updated', ['game.coins'])
	
	store.dispatch(actions.quests_create(
		"collect_coins1", "Collect 5 coins.", "coins", 5))

	store.dispatch(actions.quests_create(
		"collect_coins2", "Collect 8 coins.", "coins", 8))

func coins_updated(params: Dictionary) -> void:
	if params['path'] != 'game.coins':
		return
	
	var path : String = params['path']
	var next_value = params['next_value']
	
	var state = store.get_state()
	
	for key in state['quests']:
		var quest = state['quests'][key]
		if (quest['key'] == 'coins'
			and quest['amount'] == next_value
			and quest['completed'] == false):
			store.dispatch(actions.quests_update(key, true))
