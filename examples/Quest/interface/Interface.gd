extends Control

onready var watch := get_node('/root/watch')

func _ready():
	watch.subscribe(self, '_update_coins', ['game.coins'])
	watch.subscribe(self, '_update_quests', ['quests'])

func _update_coins(params: Dictionary):
	if params['path'] != 'game.coins':
		return
	
	$Label.text = 'Coins: ' + String(params['next_value'])

func _update_quests(params: Dictionary):
	if params['path'] != 'quests':
		return
	
	for child in $VBoxContainer.get_children():
		child.queue_free()

	var quests = params['next_value']
	for quest_name in quests.keys():
		var label = Label.new()
		label.name = quest_name
		label.text = quests[quest_name]['description']
		if quests[quest_name]['completed']:
			label.text += ' - COMPLETED'
		$VBoxContainer.add_child(label)
