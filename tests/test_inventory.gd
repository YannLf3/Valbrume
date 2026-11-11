extends TestCase


func _slots(n: int) -> Array:
	var a: Array = []
	a.resize(n)
	return a


func test_add_stack_and_overflow() -> void:
	var s: Array = _slots(2)
	eq(Inv.add(s, "wood", 10), 0)
	eq(Inv.add(s, "wood", 5), 0)
	eq(Inv.count(s, "wood"), 15)
	ok(s[1] == null, "empilé dans le même emplacement")
	var cap: int = Inv.max_stack("wood")
	eq(Inv.add(s, "wood", cap * 2), 15, "le surplus est renvoyé")


func test_quality_separate() -> void:
	var s: Array = _slots(3)
	Inv.add(s, "wood", 2, 0)
	Inv.add(s, "wood", 2, 2)
	ok(s[1] != null, "qualités différentes → piles séparées")
	eq(Inv.remove(s, "wood", 3), 3)
	eq(int(s[1]["q"]), 2, "les qualités basses partent d'abord")
	eq(Inv.count(s, "wood"), 1)


func test_move_merge_swap_sort() -> void:
	var s: Array = _slots(4)
	Inv.add(s, "wood", 3)
	s[2] = {"id": "wood", "n": 4, "q": 0}
	Inv.move(s, 2, s, 0)
	eq(int(s[0]["n"]), 7, "fusion")
	ok(s[2] == null)
	s[3] = {"id": "stone", "n": 1, "q": 0}
	Inv.move(s, 3, s, 0)
	eq(s[0]["id"], "stone", "échange")
	eq(s[3]["id"], "wood")
	Inv.sort(s)
	ok(s[0] != null and s[1] != null and s[2] == null, "tri compacté")
	eq(Inv.free_slots(s), 2)
