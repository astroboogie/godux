class_name Subscriber
extends Node

signal state_changed(params)

onready var store := get_node('/root/store')

var references := []
var prev_state := {}

func _ready() -> void:
	store.subscribe(self, '_emit')

func subscribe(target_instance: Node, target_method: String, args := []) -> void:
	connect('state_changed', target_instance, target_method)
	var reference := Closure.new(self, '_enhancer', [args])
	references.append(reference)

func _emit() -> void:
	var next_state : Dictionary = store.get_state()
	for reference in references:
		reference.call_funcv([prev_state, next_state])
	
	prev_state = next_state.duplicate()

func _enhancer(args: Array, prev_state: Dictionary, next_state: Dictionary) -> void:
	emit_signal('state_changed')

func get_class() -> String:
	return 'Subscriber'
