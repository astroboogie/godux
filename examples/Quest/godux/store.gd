# This is a singleton. Autoload it through "Scene > Project Settings > AutoLoad."

extends Node

signal state_changed(reducer, difference)

var _state := {}
var _reducers := {}

func create(reducers: Array, callbacks : Array = []) -> void:
	for reducer in reducers:
		var name : String = reducer['name']
		if not _state.has(name):
			_state[name] = {}
		if not _reducers.has(name):
			_reducers[name] = funcref(reducer['instance'], name)
			var initial_state : Dictionary = _reducers[name].call_func(
				_state[name],
				{'type': null}
			)
			_state[name] = initial_state

	if callbacks.size() > 0:
		for callback in callbacks:
			subscribe(callback['instance'], callback['name'])

func subscribe(target: Node, method: String) -> Closure:
	connect('state_changed', target, method)
	return Closure.new(self, "unsubscribe", [target, method])

func unsubscribe(target: Node, method: String) -> void:
	disconnect('state_changed', target, method)

func dispatch(action: Dictionary) -> void:
	for name in _reducers.keys():
		var state : Dictionary = _state[name]
		var next_state : Dictionary = _reducers[name].call_func(state, action)
		var difference : Dictionary = _dictionary_difference(state, next_state)
		if next_state == null:
			_state.erase(name)
			emit_signal('state_changed', null, null)
		elif state != next_state:
			_state[name] = next_state
			emit_signal('state_changed', name, difference)

func get_state() -> Dictionary:
	return _state

func _dictionary_difference(d1: Dictionary, d2: Dictionary) -> Dictionary:
	var d3 := {}
	for key in d1.keys() + d2.keys():
		if !d1.has(key):
			d3[key] = d2[key]
		elif !d2.has(key):
			d3[key] = d1[key]
		elif typeof(d1[key]) == TYPE_ARRAY and typeof(d2[key]) == TYPE_ARRAY:
			var new_array := _array_difference(d1[key], d2[key])
			if !new_array.empty():
				d3[key] = new_array
		elif typeof(d1[key]) == TYPE_DICTIONARY and typeof(d2[key]) == TYPE_DICTIONARY:
			var new_dict := _dictionary_difference(d1[key], d2[key])
			if !new_dict.empty():
				d3[key] = new_dict
		elif d1[key] != d2[key]:
			d3[key] = d2[key]
	return d3

func _array_difference(a1: Array, a2: Array) -> Array:
	var a3 := []
	for value in a1 + a2:
		if !a1.has(value):
			a3.append(value)
		elif !a2.has(value):
			a3.append(value)
	
	return a3
