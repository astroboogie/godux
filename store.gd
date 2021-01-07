extends Node

signal state_changed(name, state)

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

func subscribe(target: Node, method: String) -> void:
    # warning-ignore:return_value_discarded
    connect('state_changed', target, method)

func unsubscribe(target: Node, method: String) -> void:
    disconnect('state_changed', target, method)

func dispatch(action: Dictionary) -> void:
    for name in _reducers.keys():
        var state : Dictionary = _state[name]
        var next_state : Dictionary = _reducers[name].call_func(state, action)
        if next_state == null:
            # warning-ignore:return_value_discarded
            _state.erase(name)
            emit_signal('state_changed', name, null)
        elif state != next_state:
            _state[name] = next_state
            emit_signal('state_changed', name, next_state)

func get_state() -> Dictionary:
    return _state

func shallow_copy(dict: Dictionary) -> Dictionary:
    return shallow_merge(dict, {})

func shallow_merge(src_dict: Dictionary, dest_dict: Dictionary) -> Dictionary:
    for i in src_dict.keys():
        dest_dict[i] = src_dict[i]
    return dest_dict
