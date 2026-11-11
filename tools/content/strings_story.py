"""Textes du fil rouge, des festivals, du journal, des quêtes, du musée, du mariage et de la fin."""
from typing import Dict, Tuple


def tables() -> Dict:
    return {}


def strings() -> Dict[str, Tuple[str, str]]:
    s = {
        "REQ_HARVEST": ("Récolter %d cultures", "Harvest %d crops"), "REQ_FISH_KINDS": ("Pêcher %d espèces de poisson", "Catch %d fish species"),
        "REQ_ITEM": ("Fournir %d × %s", "Provide %d × %s"), "REQ_MONEY": ("Verser %d é", "Pay %d"),
        "REQ_FLOOR": ("Atteindre l'étage %d de la mine", "Reach floor %d of the mine"), "REQ_HEARTS": ("Cumuler %d cœurs d'amitié", "Gather %d friendship hearts"),
        "REQ_ANIMALS": ("Posséder %d animaux", "Own %d animals"), "REQ_BUILDING": ("%s niveau %d", "%s level %d"),
        "REQ_BELLS": ("Avoir fondu %d cloches", "Have cast %d bells"), "REQ_DONATED": ("Donner %d objets au musée", "Donate %d items to the museum"),
        "BELL_TITLE": ("Fonderie du Carillon", "Carillon Foundry"), "BELL_CAST": ("Fondre", "Cast"), "BELL_DONE": ("Fondue", "Cast"),
        "BELL_ALREADY": ("Cette cloche est déjà fondue.", "This bell is already cast."),
        "BELL_DARK": ("Cette cloche est encore muette.", "This bell is still silent."), "BELL_RING": ("La cloche vibre longuement.", "The bell hums for a long while."),
        "SERVICE_BELLS": ("Cloches", "Bells"), "LORE_NONE": ("Tu as lu toutes les pages.", "You've read every page."),
        "FEST_NOT_NOW": ("Pas de festival en ce moment.", "No festival right now."), "FEST_DONE": ("Tu as déjà participé à cette fête.", "You already took part in this festival."),
        "FEST_GAME_MEMORY": ("Mémoire des graines", "Seed memory"), "FEST_GAME_TIMING": ("Cadence de régate", "Regatta rhythm"),
        "FEST_GAME_JUDGING": ("Jury du potiron", "Pumpkin jury"), "FEST_GAME_TARGET": ("Boules de neige", "Snowballs"),
        "FEST_MEMORY_WATCH": ("Regarde bien la séquence…", "Watch the sequence closely..."), "FEST_MEMORY_GO": ("À toi ! (clique ou touches 1 à 4)", "Your turn! (click or keys 1 to 4)"),
        "FEST_MEMORY_ROUND": ("Manche %d / %d", "Round %d / %d"), "FEST_PRESS": ("Appuie au bon moment !", "Press at the right moment!"),
        "FEST_JUDGE_PICK": ("Choisis la récolte à présenter au jury.", "Pick the harvest to present to the jury."),
        "FEST_JUDGE_NONE": ("Tu n'as aucune récolte à présenter.", "You have no harvest to present."),
        "FEST_JUDGE_SKIP": ("Participer quand même", "Take part anyway"), "FEST_SCORE": ("Score : %d", "Score: %d"),
        "FEST_RESULT_0": ("Merci d'avoir participé !", "Thanks for taking part!"), "FEST_RESULT_1": ("Médaille de bronze !", "Bronze medal!"),
        "FEST_RESULT_2": ("Médaille d'argent ! Beau travail.", "Silver medal! Fine work."), "FEST_RESULT_3": ("Médaille d'or ! Bravo, tout le village applaudit !", "Gold medal! Bravo, the whole village applauds!"),
        "FEST_PRIZE": ("Tu reçois %d é et un lot : %s ×%d.", "You receive %d and a prize: %s ×%d."), "FEST_MONEY": ("Tu reçois %d é.", "You receive %d."),
        "JOURNAL_QUESTS": ("Quêtes", "Quests"), "JOURNAL_RELATIONS": ("Relations", "Relations"), "JOURNAL_SKILLS": ("Talents", "Skills"),
        "JOURNAL_STATS": ("Stats", "Stats"), "JOURNAL_CALENDAR": ("Calendrier", "Calendar"),
        "JOURNAL_BELLS": ("Cloches du Carillon : %d / %d", "Carillon bells: %d / %d"), "JOURNAL_ACTIVE_QUESTS": ("Quêtes en cours", "Active quests"),
        "JOURNAL_QUESTS_DONE": ("Quêtes accomplies : %d", "Quests completed: %d"), "JOURNAL_PAGES": ("Pages du registre d'Odile : %d / %d", "Pages of Odile's ledger: %d / %d"),
        "JOURNAL_DATING": ("(en couple)", "(dating)"), "JOURNAL_SPOUSE": ("(conjoint)", "(spouse)"),
        "JOURNAL_DAYS": ("Jours passés", "Days played"), "JOURNAL_HARVESTED": ("Cultures récoltées", "Crops harvested"),
        "JOURNAL_FISH": ("Poissons pêchés", "Fish caught"), "JOURNAL_MONSTERS": ("Monstres vaincus", "Monsters defeated"),
        "JOURNAL_FLOOR": ("Étage le plus profond", "Deepest floor"), "JOURNAL_SHIPPED": ("Objets expédiés", "Items shipped"),
        "JOURNAL_EARNED": ("Argent gagné", "Money earned"), "JOURNAL_DONATED": ("Dons au musée", "Museum donations"),
        "JOURNAL_PLAYTIME": ("Temps de jeu", "Playtime"), "JOURNAL_TODAY": ("Aujourd'hui : %s — %s", "Today: %s — %s"),
        "QUEST_BOARD_TITLE": ("Tableau des annonces", "Notice board"), "QUEST_ACTIVE": ("En cours (%d/%d)", "Active (%d/%d)"),
        "QUEST_AVAILABLE": ("Annonces du jour", "Today's notices"), "QUEST_NONE": ("Rien pour le moment.", "Nothing for now."),
        "QUEST_FROM": ("de %s", "from %s"), "QUEST_TURN_IN": ("Remettre", "Turn in"), "QUEST_ACCEPT": ("Accepter", "Accept"),
        "QUEST_DONE": ("Quête accomplie ! +%d é", "Quest complete! +%d"), "QUEST_FULL": ("Trop de quêtes en cours.", "Too many active quests."),
        "QUEST_GONE": ("Cette annonce a disparu.", "That notice is gone."), "QUEST_DELIVER": ("Apporter %d × %s", "Bring %d × %s"),
        "QUEST_HARVEST": ("Récolter %d cultures", "Harvest %d crops"), "QUEST_HUNT": ("Vaincre %d × %s dans la mine", "Defeat %d × %s in the mine"),
        "QUEST_FISH": ("Pêcher %d poisson(s)", "Catch %d fish"),
        "MON_PEBBLER": ("Gravillon", "Pebbler"), "MON_MOSSHOP": ("Sautemousse", "Mosshop"), "MON_EMBERBAT": ("Chauve-braise", "Emberbat"),
        "MON_FROSTSPIT": ("Crachegivre", "Frostspit"), "MON_GLOWMITE": ("Lucimite", "Glowmite"), "MON_SHELLCHARGER": ("Carapierre", "Shellcharger"),
        "MUSEUM_PROGRESS": ("Collection", "Collection"), "MUSEUM_DONATE": ("Donner", "Donate"), "MUSEUM_DONATED": ("Donné", "Donated"),
        "MUSEUM_REWARD": ("Récompense du musée", "Museum reward"), "HEAL_OK": ("Hyacinthe te soigne : te voilà d'aplomb.", "Hyacinthe tends to you: good as new."),
        "WEDDING_1": ("Le Carillon est muet, mais le village est là, au grand complet. Moi aussi.", "The Carillon is silent, but the whole village is here. So am I."),
        "WEDDING_2": ("Je n'ai pas de discours. Juste ceci : merci d'être arrivé(e) dans ma vie comme une première cloche au matin.", "I have no speech. Just this: thank you for arriving in my life like a first bell at morning."),
        "WEDDING_3": ("Alors… oui. Pour tous les matins qui viennent.", "So... yes. For every morning to come."),
        "WEDDING_DONE": ("Tu es désormais marié(e) avec %s !", "You're now married to %s!"),
        "ENDING_1": ("Chère petite pousse… Je les ai entendues, toutes les six, de très loin. Je souris à m'en faire mal aux joues.", "Dear little sprout... I heard all six of them, from very far away. I'm smiling till my cheeks ache."),
        "ENDING_2": ("Je ne suis pas partie pour fuir. Je suis partie pour que tu aies la place de devenir ce que tu es.", "I didn't leave to run away. I left so you'd have room to become who you are."),
        "ENDING_3": ("Ormelune chante de nouveau. La ferme prospère, les amis sont là, la vallée respire. Voilà ce qu'on appelle un foyer.", "Ormelune sings again. The farm thrives, friends are near, the valley breathes. That's what we call a home."),
        "ENDING_4": ("Continue, si tu veux. Il reste des saisons, des cloches à accorder, des gens à aimer. Je t'embrasse. — Odile", "Carry on, if you like. There are seasons left, bells to tune, people to love. Hugs. — Odile"),
    }
    return s
