class_name Loc
extends RefCounted
## Traduction utilisable depuis du code statique (où `tr()` n'existe pas).


static func t(key: String) -> String:
	return TranslationServer.translate(StringName(key))


static func f(key: String, args: Array) -> String:
	return TranslationServer.translate(StringName(key)) % args
