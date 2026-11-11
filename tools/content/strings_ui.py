"""Textes d'interface, d'infobulles et de messages. Clé → (français, anglais)."""
from typing import Dict, Tuple


def tables() -> Dict:
    return {}


def strings() -> Dict[str, Tuple[str, str]]:
    return {
        # génériques
        "COMMON_BACK": ("Retour", "Back"), "COMMON_OK": ("OK", "OK"), "COMMON_YES": ("Oui", "Yes"), "COMMON_NO": ("Non", "No"),
        "COMMON_CLOSE": ("Fermer", "Close"), "COMMON_CONTINUE": ("Continuer", "Continue"), "COMMON_CANCEL": ("Annuler", "Cancel"),
        "MAP_FARM": ("La ferme", "The Farm"), "MAP_FARMHOUSE": ("La maison", "The House"),
        # titre et sauvegardes
        "TITLE_PLAY": ("Jouer", "Play"), "TITLE_OPTIONS": ("Options", "Options"), "TITLE_CREDITS": ("Crédits", "Credits"),
        "TITLE_QUIT": ("Quitter", "Quit"), "SLOTS_TITLE": ("Choisis une sauvegarde", "Choose a save"),
        "SLOT_N": ("Sauvegarde %d", "Save %d"), "SLOT_EMPTY": ("— vide —", "— empty —"),
        "SLOT_INFO": ("%s · %s · jour %d", "%s · %s · day %d"), "SLOT_CONTINUE": ("Continuer", "Continue"),
        "SLOT_NEW": ("Nouvelle partie", "New game"), "SLOT_DELETE": ("Supprimer", "Delete"),
        "DELETE_CONFIRM": ("Supprimer définitivement cette sauvegarde ?", "Permanently delete this save?"),
        "NEW_TITLE": ("Nouvelle partie", "New game"), "NEW_NAME": ("Ton prénom", "Your name"),
        "NEW_FARM": ("Nom de la ferme", "Farm name"), "NEW_OUTFIT": ("Tenue", "Outfit"), "NEW_START": ("Commencer", "Start"),
        "DEFAULT_NAME": ("Camille", "Sam"), "DEFAULT_FARM": ("Les Trois Sillons", "Three Furrows"),
        "CREDITS_TEXT": ("Valbrume\n\nConception, programmation, pixel art,\nmusique et sons : tout est généré\npar les scripts de ce dépôt.\n\nAucun asset externe.\nMoteur : Godot (licence MIT).",
                         "Valbrume\n\nDesign, code, pixel art,\nmusic and sound: everything is generated\nby the scripts in this repository.\n\nNo external assets.\nEngine: Godot (MIT license)."),
        # pause et options
        "PAUSE_TITLE": ("Pause", "Paused"), "PAUSE_RESUME": ("Reprendre", "Resume"), "PAUSE_SAVE": ("Sauvegarder", "Save"),
        "PAUSE_OPTIONS": ("Options", "Options"), "PAUSE_TO_TITLE": ("Retour au titre", "Back to title"),
        "OPT_TITLE": ("Options", "Options"), "OPT_LANGUAGE": ("Langue", "Language"), "OPT_MASTER": ("Volume général", "Master volume"),
        "OPT_MUSIC": ("Musique", "Music"), "OPT_SFX": ("Effets", "Effects"), "OPT_KEYS": ("Touches de déplacement", "Movement keys"),
        "OPT_KEYS_AUTO": ("Auto (WASD + flèches)", "Auto (WASD + arrows)"), "OPT_KEYS_WASD": ("WASD", "WASD"),
        "OPT_KEYS_ZQSD": ("ZQSD", "ZQSD"), "OPT_KEYS_ARROWS": ("Flèches", "Arrows"),
        "OPT_FULLSCREEN": ("Plein écran", "Fullscreen"), "OPT_TOUCH": ("Commandes tactiles", "Touch controls"),
        "OPT_TOUCH_AUTO": ("Auto", "Auto"), "OPT_TOUCH_ON": ("Toujours", "Always"), "OPT_TOUCH_OFF": ("Jamais", "Never"),
        "OPT_UI_SCALE": ("Taille de l'interface", "Interface size"), "OPT_SPEED": ("Secondes par minute de jeu", "Seconds per game minute"),
        "OPT_SHAKE": ("Secousses d'écran", "Screen shake"), "OPT_FPS": ("Afficher les images/s", "Show FPS"),
        "OPT_REMAP": ("Touches…", "Keys…"), "LANG_FR": ("Français", "Français"), "LANG_EN": ("English", "English"),
        # inventaire et infobulles
        "INV_TITLE": ("Sac", "Bag"), "INV_SORT": ("Trier", "Sort"), "BIN_TITLE": ("Coffre d'expédition", "Shipping chest"),
        "CHEST_TITLE": ("Coffre", "Chest"),
        "TIP_SELL": ("Vaut %d", "Worth %d"), "QUALITY_1": ("Argent", "Silver"), "QUALITY_2": ("Or", "Gold"),
        "TIP_ENERGY": ("+%d énergie", "+%d energy"), "TIP_HEALTH": ("+%d santé", "+%d health"),
        "TIP_BUFF": ("Bonus : %s +%d", "Buff: %s +%d"), "TIP_TOOL_LEVEL": ("Niveau %d", "Level %d"),
        # messages
        "TOAST_LEVEL_UP": ("%s : niveau %d !", "%s: level %d!"), "TOAST_RECIPE": ("Recette apprise : %s", "Recipe learned: %s"),
        "TOAST_INV_FULL": ("Ton sac est plein !", "Your bag is full!"), "TOAST_TOO_WEAK": ("Ton outil est trop faible.", "Your tool is too weak."),
        "TOAST_NO_ENERGY": ("Tu es trop fatigué(e).", "You're too tired."), "TOAST_CAN_EMPTY": ("L'arrosoir est vide.", "The can is empty."),
        "TOAST_CAN_FILLED": ("Arrosoir rempli.", "Watering can filled."), "TOAST_NEED_SOIL": ("Il faut de la terre labourée.", "You need tilled soil."),
        "TOAST_OCCUPIED": ("Il y a déjà une plante ici.", "There's already a plant here."),
        "TOAST_WRONG_SEASON": ("Ce n'est pas la bonne saison.", "Wrong season for this crop."),
        "TOAST_CANT_PLACE": ("Impossible de poser ça ici.", "You can't place that here."),
        "TOAST_INDOORS_ONLY": ("Ça se pose à l'intérieur.", "That goes indoors."),
        "TOAST_OUTDOORS_ONLY": ("Ça se pose dehors.", "That goes outdoors."),
        "TOAST_NEEDS_WALL": ("Ça se pose sur un mur.", "That goes on a wall."),
        "TOAST_NEEDS_WATER": ("Ça se pose dans l'eau.", "That goes in water."),
        "TOAST_CHEST_NOT_EMPTY": ("Vide d'abord le coffre.", "Empty the chest first."),
        "TOAST_MACHINE_BUSY": ("La machine travaille encore.", "The machine is still working."),
        "TOAST_PATH_CLOSED": ("Le chemin n'est pas encore praticable.", "The path isn't passable yet."),
        "TOAST_SAVED": ("Partie sauvegardée.", "Game saved."), "TOAST_DOOR_LOCKED": ("C'est fermé.", "It's locked."),
        "TOAST_NOTHING_HERE": ("Rien à faire ici.", "Nothing to do here."),
        # sommeil et bilan
        "SLEEP_ASK": ("Aller dormir ?", "Go to sleep?"), "SLEEP_YES": ("Dormir", "Sleep"), "SLEEP_NO": ("Pas encore", "Not yet"),
        "SUMMARY_TITLE": ("Bilan du jour %d", "Day %d summary"), "SUMMARY_SHIPPED": ("Expédié cette nuit", "Shipped overnight"),
        "SUMMARY_NOTHING": ("Rien n'a été expédié.", "Nothing was shipped."), "SUMMARY_TOTAL": ("Total", "Total"),
        "SUMMARY_FAINTED": ("La fatigue a eu raison de toi : %d é perdus.", "Exhaustion got the better of you: %d lost."),
        "SUMMARY_PESTS": ("Les grignotins ont mangé %d plant(s).", "Nibblers ate %d plant(s)."),
        "SUMMARY_TOMORROW": ("Demain : %s", "Tomorrow: %s"), "SUMMARY_SEASON": ("Une nouvelle saison commence : %s !", "A new season begins: %s!"),
        "FORECAST": ("La rainette annonce pour demain : %s.", "The frog forecasts for tomorrow: %s."),
        "MAILBOX_EMPTY": ("La boîte aux lettres est vide.", "The mailbox is empty."),
        # introduction
        "INTRO_SPEAKER": ("Tante Odile", "Aunt Odile"),
        "INTRO_1": ("Chère petite pousse, si tu lis ceci, c'est que j'ai enfin pris la route du grand large. La ferme est à toi : le toit fuit un peu, la terre est têtue, mais elle est bonne.",
                    "Dear little sprout, if you're reading this, I've finally set off for the open road. The farm is yours: the roof leaks a little and the soil is stubborn, but it's good soil."),
        "INTRO_2": ("Au village d'Ormelune, le Carillon s'est tu le jour de mon départ. Six cloches, six voix : c'est moi qui les fondais. Aucune ne sonne plus.",
                    "In the village of Ormelune, the Carillon fell silent the day I left. Six bells, six voices: I cast them myself. Not one of them rings anymore."),
        "INTRO_3": ("Fais-toi des amis, cultive la terre, descends à la mine si tu l'oses. Quand tu auras de quoi refondre mes cloches, tu comprendras pourquoi c'est toi.",
                    "Make friends, work the land, go down the mine if you dare. When you have enough to recast my bells, you'll understand why it had to be you."),
        "INTRO_4": ("P.-S. La clé du hangar est sous le seau. Le seau est dans la mare. Bon courage !",
                    "P.S. The shed key is under the bucket. The bucket is in the pond. Good luck!"),
    }
