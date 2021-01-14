class_name Store
extends Node

signal state_changed()

var _state := {}
var _reducers := {}

# Initializes the global state and the reducers.
func create(reducers: Array, callbacks : Array = []) -> void:
    for reducer in reducers:
        var name : String = reducer['name']
        if !_state.has(name):
            _state[name] = {}
        if !_reducers.has(name):
            _reducers[name] = funcref(reducer['instance'], name)
            var initial_state : Dictionary = _reducers[name].call_func(
                _state[name],
                {'type': null}
            )
            _state[name] = initial_state

    if callbacks.size() > 0:
        for callback in callbacks:
            subscribe(callback['instance'], callback['name'])

# Makes the method in the target node a state listener.
func subscribe(target_instance: Node, target_method: String) -> Closure:
    connect('state_changed', target_instance, target_method)
    return Closure.new(self, "unsubscribe", [target_instance, target_method])

# Disconnects the method in the target node as a state listener.
func unsubscribe(target_instance: Node, target_method: String) -> void:
    disconnect('state_changed', target_instance, target_method)

# Dispatches an action.
func dispatch(action: Dictionary) -> void:
    for name in _reducers.keys():
        var state : Dictionary = _state[name]
        var next_state : Dictionary = _reducers[name].call_func(state, action)
        if next_state == null:
            _state.erase(name)
            emit_signal('state_changed')
        elif state != next_state:
            _state[name] = next_state
            emit_signal('state_changed')

# Returns the store's state.
func get_state() -> Dictionary:
    return _state
