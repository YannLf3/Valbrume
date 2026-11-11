class_name Inv
extends RefCounted
## Opérations d'inventaire sur un tableau d'emplacements.
## Un emplacement vaut `null` ou {"id": String, "n": int, "q": int}.


static func max_stack(id: String) -> int:
	return int(Database.item(id).get("stack", Database.bal_i("stack_size", 999)))


## Ajoute des objets ; renvoie la quantité qui n'a pas pu entrer.
static func add(slots: Array, id: String, count: int = 1, quality: int = 0) -> int:
	var cap: int = max_stack(id)
	var left: int = count
	if cap > 1:
		for i: int in slots.size():
			var s: Variant = slots[i]
			if left > 0 and s != null and s["id"] == id and int(s["q"]) == quality and int(s["n"]) < cap:
				var put: int = mini(left, cap - int(s["n"]))
				s["n"] = int(s["n"]) + put
				left -= put
	for i: int in slots.size():
		if left <= 0:
			break
		if slots[i] == null:
			var put2: int = mini(left, cap)
			slots[i] = {"id": id, "n": put2, "q": quality}
			left -= put2
	return left


static func can_add(slots: Array, id: String, count: int = 1, quality: int = 0) -> bool:
	var cap: int = max_stack(id)
	var room: int = 0
	for s: Variant in slots:
		if s == null:
			room += cap
		elif s["id"] == id and int(s["q"]) == quality:
			room += cap - int(s["n"])
		if room >= count:
			return true
	return false


static func count(slots: Array, id: String) -> int:
	var total: int = 0
	for s: Variant in slots:
		if s != null and s["id"] == id:
			total += int(s["n"])
	return total


## Retire `n` objets (les qualités basses d'abord) ; renvoie la quantité retirée.
static func remove(slots: Array, id: String, n: int) -> int:
	var left: int = n
	for q: int in 3:
		for i: int in slots.size():
			var s: Variant = slots[i]
			if left > 0 and s != null and s["id"] == id and int(s["q"]) == q:
				var take: int = mini(left, int(s["n"]))
				s["n"] = int(s["n"]) - take
				left -= take
				if int(s["n"]) <= 0:
					slots[i] = null
	return n - left


## Retire `n` objets de l'emplacement `index` ; renvoie la pile retirée ({} si vide).
static func take(slots: Array, index: int, n: int) -> Dictionary:
	if index < 0 or index >= slots.size() or slots[index] == null:
		return {}
	var s: Dictionary = slots[index]
	var got: int = mini(n, int(s["n"]))
	var out: Dictionary = {"id": s["id"], "n": got, "q": int(s["q"])}
	s["n"] = int(s["n"]) - got
	if int(s["n"]) <= 0:
		slots[index] = null
	return out


## Déplace/échange/fusionne entre deux emplacements (glisser-déposer).
static func move(from: Array, i: int, to: Array, j: int) -> void:
	if i < 0 or j < 0 or i >= from.size() or j >= to.size():
		return
	if from == to and i == j:
		return
	var a: Variant = from[i]
	var b: Variant = to[j]
	if a == null:
		return
	if b != null and b["id"] == a["id"] and int(b["q"]) == int(a["q"]):
		var cap: int = max_stack(a["id"])
		var put: int = mini(int(a["n"]), cap - int(b["n"]))
		b["n"] = int(b["n"]) + put
		a["n"] = int(a["n"]) - put
		if int(a["n"]) <= 0:
			from[i] = null
		return
	from[i] = b
	to[j] = a


## Fusionne les piles puis trie par catégorie, puis par nom d'identifiant.
static func sort(slots: Array, first: int = 0) -> void:
	var stacks: Array = []
	for i: int in range(first, slots.size()):
		if slots[i] != null:
			stacks.append(slots[i])
		slots[i] = null
	stacks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ca: String = str(Database.item(a["id"]).get("cat", "zz"))
		var cb: String = str(Database.item(b["id"]).get("cat", "zz"))
		if ca != cb:
			return ca < cb
		if a["id"] != b["id"]:
			return str(a["id"]) < str(b["id"])
		return int(a["q"]) > int(b["q"]))
	var tmp: Array = []
	tmp.resize(slots.size() - first)
	for s: Dictionary in stacks:
		add(tmp, s["id"], int(s["n"]), int(s["q"]))
	for i: int in tmp.size():
		slots[first + i] = tmp[i]


static func free_slots(slots: Array) -> int:
	var n: int = 0
	for s: Variant in slots:
		if s == null:
			n += 1
	return n
