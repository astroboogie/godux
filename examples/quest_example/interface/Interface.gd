extends Control

onready var store := get_node('/root/store')

func _ready():
	store.subscribe(self, '_update_coins')
	store.subscribe(self, '_update_quests')

func _update_coins(name, difference):
	if name != 'game':
		return
	
	print(difference)
	
	if 'coins' in difference:
		$Label.text = 'Coins: ' + String(difference['coins'])

func _update_quests(name, difference):
	if name != 'quests':
		return
	
	for child in $VBoxContainer.get_children():
		child.queue_free()
	
	var quests = store.get_state()['quests']
	for quest_name in quests.keys():
		var label = Label.new()
		label.name = quest_name
		label.text = quests[quest_name]['description']
		if quests[quest_name]['completed']:
			label.text += ' - COMPLETED'
		$VBoxContainer.add_child(label)
