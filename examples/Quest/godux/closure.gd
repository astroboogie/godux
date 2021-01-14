# Created by xananax

extends Reference
class_name Closure

var _object
var _method
var _arguments

func _init(object: Object, method: String, arguments := []) -> void:
	assert(object.has_method(method), "Object %s doesn't have a method called %s" % [object, method])
	_object = object
	_method = method
	_arguments = arguments

func call_funcv(additional_arguments := []):
	return _object.callv(_method, _arguments + additional_arguments)
