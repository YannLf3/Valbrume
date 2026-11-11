class_name Economy
extends RefCounted
## Prix de vente (qualité + bonus de compétence).

const CAT_PERK: Dictionary = {
	"crop": "crop_price", "fruit": "crop_price", "animal": "animal_price", "artisan": "animal_price",
	"fish": "fish_price", "mineral": "mineral_price", "ingot": "mineral_price", "forage": "forage_price",
}


static func sell_value(id: String, quality: int = 0) -> int:
	var base: int = Database.sell_price(id, quality)
	var cat: String = str(Database.item(id).get("cat", ""))
	var perk_name: String = str(CAT_PERK.get(cat, ""))
	var mult: float = 1.0 + (Skills.perk(perk_name) if perk_name != "" else 0.0)
	return int(round(base * mult))


static func slot_value(slot: Variant) -> int:
	if slot == null:
		return 0
	return sell_value(str(slot["id"]), int(slot["q"])) * int(slot["n"])
