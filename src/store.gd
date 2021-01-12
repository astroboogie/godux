extends Node

signal state_changed(reducer, difference)

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
func subscribe(target: Node, method: String) -> Closure:
    connect('state_changed', target, method)
    return Closure.new(self, "unsubscribe", [target, method])

# Disconnects the method in the target node as a state listener.
func unsubscribe(target: Node, method: String) -> void:
    disconnect('state_changed', target, method)

# Dispatches an action.
func dispatch(action: Dictionary) -> void:
    for name in _reducers.keys():
        var state : Dictionary = _state[name]
        var next_state : Dictionary = _reducers[name].call_func(state, action)
        var difference : Dictionary = _dictionary_difference(state, next_state, true)
        if next_state == null:
            _state.erase(name)
            emit_signal('state_changed', null, null)
        elif state != next_state:
            _state[name] = next_state
            emit_signal('state_changed', name, difference)

# Returns the store's state.
func get_state() -> Dictionary:
    return _state

# Returns a dictionary containing 'op,' the type of difference between d1 and
# d2, and 'diff,' a dictionary representing changes between d1 and d2.
func _dictionary_difference(d1: Dictionary, d2: Dictionary, root := false) -> Dictionary:
    var d3 := {}
    if root:
        d3['op'] = 'undefined'
        d3['diff'] = {}
    
    for key in d1.keys() + d2.keys():
        if !d1.has(key):
            if root:
                d3['op'] = 'add'
                d3['diff'][key] = d2[key]
            else:
                d3[key] = d2[key]
        elif !d2.has(key):
            if root:
                d3['op'] = 'delete'
                d3['diff'][key] = d1[key]
            else:
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
            if root:
                d3['op'] = 'update'
                d3['diff'][key] = d2[key]
            else:
                d3[key] = d2[key]
    return d3

# Returns an array containing the differences between a1 and a2.
func _array_difference(a1: Array, a2: Array) -> Array:
    var a3 := []
    for value in a1 + a2:
        if !a1.has(value):
            a3.append(value)
        elif !a2.has(value):
            a3.append(value)
    
    return a3
