extends Node
## Bus d'événements global : les systèmes émettent, l'affichage écoute.
## Aucun état ici, uniquement des signaux.

# --- temps ---
signal minute_passed(minutes: int)
signal hour_passed(hour: int)
signal day_started(day: int)
signal night_started()
signal day_ended(summary: Dictionary)
signal season_changed(season: int)
signal weather_changed(weather: String)

# --- joueur ---
signal money_changed(amount: int)
signal energy_changed(value: float, max_value: float)
signal health_changed(value: float, max_value: float)
signal inventory_changed()
signal hotbar_changed(index: int)
signal item_gained(id: String, count: int, quality: int)
signal buffs_changed()
signal skill_xp_gained(skill: String, amount: int)
signal skill_level_up(skill: String, level: int)
signal player_fainted(reason: String)

# --- monde ---
signal map_changed(map_id: String)
signal soil_changed(map_id: String, cell: Vector2i)
signal object_changed(map_id: String, cell: Vector2i)
signal map_rebuild_requested(map_id: String)
signal animals_changed()
signal monster_killed(kind: String)
signal fish_caught(id: String, quality: int)

# --- social / progression ---
signal friendship_changed(npc: String, points: int)
signal quest_updated()
signal story_progress(bell: String)
signal collection_updated()
signal recipe_learned(id: String)

# --- interface ---
signal toast(text: String, icon_item: String)
signal ui_requested(screen: String, args: Dictionary)
signal ui_closed(screen: String)
signal dialog_finished(tag: String)
signal input_mode_changed(mode: int)
signal settings_changed()
signal language_changed()
signal screen_shake(strength: float)
signal fx_requested(kind: String, world_pos: Vector2)
