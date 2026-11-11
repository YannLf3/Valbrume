class_name TestCase
extends RefCounted
## Base des tests : assertions simples, comptées par le runner.

var failures: Array[String] = []
var checks: int = 0
var _current: String = ""


func begin(test_name: String) -> void:
	_current = test_name


func before_each() -> void:
	pass


func ok(cond: bool, msg: String = "") -> void:
	checks += 1
	if not cond:
		failures.append("%s : %s" % [_current, msg])


func eq(a: Variant, b: Variant, msg: String = "") -> void:
	checks += 1
	if typeof(a) != typeof(b) and not (typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]):
		failures.append("%s : %s (types %s ≠ %s : %s / %s)" % [_current, msg, typeof(a), typeof(b), str(a), str(b)])
	elif a != b:
		failures.append("%s : %s (obtenu %s, attendu %s)" % [_current, msg, str(a), str(b)])


func near(a: float, b: float, eps: float = 0.001, msg: String = "") -> void:
	checks += 1
	if absf(a - b) > eps:
		failures.append("%s : %s (obtenu %f, attendu %f)" % [_current, msg, a, b])
