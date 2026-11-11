class_name MonsterManager
extends Node
## Monstres de l'étage courant : apparition, contacts, projectiles (pool), attaque à l'épée, butin.

signal player_died()

const POOL: int = 12
const CONTACT_RADIUS: float = 11.0
const PROJECTILE_SPEED: float = 74.0
const PROJECTILE_LIFE: float = 2.4
const PROJECTILE_RADIUS: float = 7.0
const KILL_LADDER_CHANCE: float = 0.15

var rt: MapRuntime
var player: Player
var container: Node2D
var monsters: Array[MonsterEntity] = []
var invincible: float = 0.0
var _pool: Array[Sprite2D] = []
var _vel: PackedVector2Array = PackedVector2Array()
var _life: PackedFloat32Array = PackedFloat32Array()
var _dmg: PackedInt32Array = PackedInt32Array()


func _ready() -> void:
	_vel.resize(POOL)
	_life.resize(POOL)
	_dmg.resize(POOL)


func setup(p_rt: MapRuntime, p_container: Node2D, p_player: Player) -> void:
	rt = p_rt
	container = p_container
	player = p_player
	for m: MonsterEntity in monsters:
		m.queue_free()
	monsters.clear()
	for i: int in _pool.size():
		_life[i] = 0.0
		_pool[i].visible = false
	if not rt.data.has("monsters"):
		set_process(false)
		return
	set_process(true)
	var killed: Array = rt.state.get("killed", [])
	var list: Array = rt.data["monsters"]
	for i: int in list.size():
		if killed.has(i):
			continue
		var d: Dictionary = list[i]
		var m: MonsterEntity = MonsterEntity.new()
		m.kind = str(d["k"])
		m.rt = rt
		m.target = player
		m.index = i
		container.add_child(m)
		m.place_cell(Vector2i(int(d["x"]), int(d["y"])))
		m.died.connect(_on_died)
		m.shot.connect(_on_shot)
		monsters.append(m)


func _process(delta: float) -> void:
	invincible = maxf(0.0, invincible - delta)
	if player == null or GameState.health <= 0.0:
		return
	var pc: Vector2 = player.position + Vector2(0, -8)
	for m: MonsterEntity in monsters:
		if invincible <= 0.0 and (m.position + Vector2(0, -8)).distance_to(pc) < CONTACT_RADIUS:
			_hit_player(m.contact_damage(), m.position)
	for i: int in _pool.size():
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		var sp: Sprite2D = _pool[i]
		sp.position += _vel[i] * delta
		var c: Vector2i = MapRuntime.cell_of_pixel(sp.position)
		if _life[i] <= 0.0 or rt.is_solid(c):
			_life[i] = 0.0
			sp.visible = false
		elif invincible <= 0.0 and sp.position.distance_to(pc) < PROJECTILE_RADIUS:
			_life[i] = 0.0
			sp.visible = false
			_hit_player(_dmg[i], sp.position - _vel[i])


func _hit_player(raw: int, from: Vector2) -> void:
	invincible = Database.bal_f("invincible_time", 0.9)
	Combat.hurt_player(raw)
	player.modulate = Color(1.8, 0.5, 0.5)
	create_tween().tween_property(player, "modulate", Color.WHITE, invincible)
	var push: Vector2 = (player.position - from).normalized() * 6.0
	if not player._blocked_at(player.position + push):
		player.position += push
	if Combat.is_dead():
		player_died.emit()


func _on_shot(origin: Vector2, direction: Vector2, damage: int) -> void:
	for i: int in POOL:
		if i >= _pool.size():
			var sp: Sprite2D = Sprite2D.new()
			sp.texture = Database.sprite("p_frost")
			sp.z_index = 30
			container.add_child(sp)
			_pool.append(sp)
		if _life[i] <= 0.0:
			var s: Sprite2D = _pool[i]
			s.position = origin
			s.visible = true
			_vel[i] = direction * PROJECTILE_SPEED
			_life[i] = PROJECTILE_LIFE
			_dmg[i] = damage
			AudioManager.sfx("shoot")
			return


## Coup d'épée : touche les monstres devant le joueur (portée et arc de la balance).
func attack(sword_level: int) -> int:
	var f: Vector2 = Vector2(Player.FACING_VEC[player.facing])
	var origin: Vector2 = player.position + Vector2(0, -8)
	var reach: float = Database.bal_f("sword_reach", 22.0)
	var half_arc: float = deg_to_rad(Database.bal_f("sword_arc", 110.0)) / 2.0
	var hits: int = 0
	for m: MonsterEntity in monsters.duplicate():
		var to_m: Vector2 = (m.position + Vector2(0, -8)) - origin
		if to_m.length() <= reach + 6.0 and absf(f.angle_to(to_m)) <= half_arc:
			var r: Dictionary = Combat.roll_hit(sword_level)
			hits += 1
			if bool(r["crit"]):
				EventBus.fx_requested.emit("sparkle", m.position + Vector2(0, -10))
			m.hurt(int(r["damage"]), origin)
	AudioManager.sfx("sword")
	return hits


func _on_died(m: MonsterEntity) -> void:
	var def: Dictionary = m.def
	for drop: Array in def.get("drops", []):
		if WorldObjects.rng.randf() <= float(drop[3]):
			Loot.give(str(drop[0]), WorldObjects.rng.randi_range(int(drop[1]), int(drop[2])))
	Skills.add_xp("combat", int(def["xp"]))
	GameState.add_stat("monsters_killed", 1, m.kind)
	EventBus.monster_killed.emit(m.kind)
	EventBus.fx_requested.emit("smoke", m.position + Vector2(0, -8))
	AudioManager.sfx("monster_die")
	var killed: Array = rt.state.get("killed", [])
	killed.append(m.index)
	rt.state["killed"] = killed
	monsters.erase(m)
	m.queue_free()
	if WorldObjects.rng.randf() < KILL_LADDER_CHANCE:
		MineGen.reveal_ladder(rt)
