class_name Watch
extends Subscriber

func _enhancer(args: Array, prev_state: Dictionary, next_state: Dictionary) -> void:
    assert(args.size() == 1, 'Too many args provided')
    
    var path : String = args[0]
    var prev_value = prev_state
    var next_value = next_state
    
    for key in path.split('.', false):
        if range(18, 27).has(typeof(prev_value)) and prev_value.has(key):
            prev_value = prev_value[key]
        else:
            prev_value = null
        
        if range(18, 27).has(typeof(next_value)) and next_value.has(key):
            next_value = next_value[key]
        else:
            next_value = null
        
        if (prev_value == null and next_value == null
            or prev_value == next_value):
            return
    
    var params := { 'path': path, 'prev_value': prev_value, 'next_value': next_value }
    emit_signal('state_changed', params)

func get_class() -> String:
    return 'Watch'
