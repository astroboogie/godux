extends Area2D

onready var store := get_node('/root/store')
onready var actions := get_node('/root/actions')

func _on_entered(body_id, body, body_shape, area_shape):
	if body.name == 'Player':
		store.dispatch(actions.game_add_coins(1))
		queue_free()
