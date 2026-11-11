class_name Loot
extends RefCounted
## Attribution d'objets au joueur.


## Ajoute à l'inventaire ; renvoie vrai si tout est entré (sinon prévient le joueur).
static func give(id: String, n: int = 1, quality: int = 0) -> bool:
	if n <= 0:
		return true
	var left: int = GameState.add_item(id, n, quality)
	if left > 0:
		EventBus.toast.emit(Loc.t("TOAST_INV_FULL"), id)
	return left == 0
