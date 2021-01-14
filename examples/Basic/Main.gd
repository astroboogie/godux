# Attach this scene to a root scene node, not as a singleton. Make sure to include the store.gd file in your project.

extends Node

onready var actions = get_node('/root/actions')
onready var reducers = get_node('/root/reducers')
onready var store = get_node('/root/store')

func _ready() -> void:
    store.create([
        {'name': 'game', 'instance': reducers},
        {'name': 'player', 'instance': reducers}
    ])
    
    store.dispatch(actions.game_set_start_time(OS.get_unix_time()))
    store.dispatch(actions.player_set_name('Goku'))
    store.dispatch(actions.player_set_health(9000))

    print(store.get_state())
