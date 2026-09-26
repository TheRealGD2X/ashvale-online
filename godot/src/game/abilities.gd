class_name Abilities
## Every class ability: what it costs, how long it takes, how far it reaches, what it does and how
## it looks. A character knows many abilities (the spellbook) but has only FIVE on the bar at once;
## choosing the right five is part of the game.
##
## Magnitudes are  base + per_level × level  (+ a share of attack or spell power), so an ability
## keeps pace as you level. Costs: Rage is absolute; mana is a percentage of the base mana pool.
##
## kind:  strike (weapon hit) · spell (damage at target, maybe projectile) · dot · heal · hot ·
##        shield · aoe (around you) · ground (at a point) · charge · buff · debuff · taunt · blink

const LIST := {
	# ------------------------------------------------------------------ Warrior
	"heroic_strike": {"name": "Heroic Strike", "cls": "warrior", "level": 1, "school": "physical", "cost": 15,
		"kind": "strike", "range": Rules.MELEE_RANGE, "bonus": [7, 2.0], "threat": 1.5, "anim": "Sword_Regular_B", "fx": "slash_gold",
		"icon": ["⚔", Color(0.9, 0.7, 0.3)], "desc": "A mighty blow that deals your weapon damage plus {bonus}, and draws extra attention."},
	"charge": {"name": "Charge", "cls": "warrior", "level": 1, "school": "physical", "cost": -15, "cd": 15.0, "gcd": false,
		"kind": "charge", "min_range": 7.0, "range": 25.0, "stun": 1.2, "ooc": true, "anim": "Sword_Dash", "fx": "charge",
		"icon": ["➶", Color(0.85, 0.45, 0.25)], "desc": "Rush at an enemy, stunning it for 1 second and generating 15 Rage. Only usable before combat."},
	"rend": {"name": "Rend", "cls": "warrior", "level": 1, "school": "physical", "cost": 10,
		"kind": "dot", "range": Rules.MELEE_RANGE, "total": [15, 4.2], "dur": 15.0, "tick": 3.0, "anim": "Sword_Regular_A", "fx": "rend",
		"icon": ["✂", Color(0.8, 0.2, 0.2)], "desc": "Wounds the target, causing {total} bleed damage over 15 seconds."},
	"thunder_clap": {"name": "Thunder Clap", "cls": "warrior", "level": 1, "school": "physical", "cost": 20, "cd": 6.0,
		"kind": "aoe", "radius": 8.0, "dmg": [8, 2.4], "slow_attack": 0.1, "dur": 10.0, "anim": "NinjaJump_Land", "fx": "thunderclap",
		"icon": ["☄", Color(0.55, 0.7, 1.0)], "desc": "Slam the ground, dealing {dmg} damage to every enemy within 8 metres and slowing their attacks by 10%."},
	"execute": {"name": "Execute", "cls": "warrior", "level": 1, "school": "physical", "cost": 15, "all_rage": true,
		"kind": "strike", "range": Rules.MELEE_RANGE, "bonus": [30, 7.0], "per_rage": [1.5, 0.35], "below": 0.2, "anim": "Sword_Regular_C", "fx": "execute",
		"icon": ["☠", Color(0.95, 0.25, 0.1)], "desc": "Finish off an enemy below 20% health, dealing {bonus} damage plus more for each extra point of Rage."},
	"battle_shout": {"name": "Battle Shout", "cls": "warrior", "level": 1, "school": "physical", "cost": 10,
		"kind": "buff", "self": true, "aura": "battle_shout", "ap": [12, 2.5], "dur": 120.0, "anim": "Idle_Shield", "fx": "shout",
		"icon": ["📯", Color(0.95, 0.75, 0.2)], "desc": "A rallying cry that raises your attack power by {ap} for 2 minutes."},
	"hamstring": {"name": "Hamstring", "cls": "warrior", "level": 1, "school": "physical", "cost": 10,
		"kind": "debuff", "range": Rules.MELEE_RANGE, "dmg": [4, 0.8], "slow": 0.5, "dur": 15.0, "anim": "Melee_Hook", "fx": "slash_red",
		"icon": ["⚓", Color(0.75, 0.55, 0.4)], "desc": "Cripples the target, dealing {dmg} damage and slowing its movement by 50% for 15 seconds."},
	"taunt": {"name": "Taunt", "cls": "warrior", "level": 1, "school": "physical", "cost": 0, "cd": 10.0, "gcd": false,
		"kind": "taunt", "range": 12.0, "dur": 3.0, "anim": "Idle_No", "fx": "taunt",
		"icon": ["☝", Color(0.95, 0.35, 0.3)], "desc": "Force an enemy to attack you for 3 seconds and become its top concern."},

	"defensive_stance": {"name": "Defensive Stance", "cls": "warrior", "level": 10, "school": "physical", "cost": 0, "cd": 1.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "defensive_stance", "dmg_taken": -0.1, "dmg_pct": -0.1, "threat": 1.5, "dur": 3600.0, "anim": "Idle_Shield", "fx": "shout",
		"icon": ["⛉", Color(0.55, 0.65, 0.9)], "desc": "A guarded stance: you take 10% less damage and deal 10% less, but everything you do draws two and a half times the attention. For tanking."},
	"shield_block": {"name": "Shield Block", "cls": "warrior", "level": 16, "school": "physical", "cost": 10, "cd": 12.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "shield_block", "dmg_taken": -0.3, "dur": 6.0, "anim": "Idle_Shield", "fx": "shout",
		"icon": ["⛊", Color(0.7, 0.75, 0.85)], "desc": "Brace behind your shield: you take 30% less damage for 6 seconds."},
	"mortal_strike": {"name": "Mortal Strike", "cls": "warrior", "level": 20, "school": "physical", "cost": 30, "cd": 6.0,
		"kind": "strike", "range": Rules.MELEE_RANGE, "bonus": [25, 3.4], "anim": "Sword_Heavy_Combo", "fx": "execute",
		"icon": ["⚚", Color(0.85, 0.3, 0.25)], "desc": "A vicious strike that deals your weapon damage plus {bonus}."},
	"whirlwind": {"name": "Whirlwind", "cls": "warrior", "level": 26, "school": "physical", "cost": 25, "cd": 10.0,
		"kind": "aoe", "radius": 8.0, "dmg": [22, 4.8], "anim": "Sword_Regular_C", "fx": "thunderclap",
		"icon": ["✵", Color(0.9, 0.8, 0.5)], "desc": "Spin with your weapon out, dealing {dmg} damage to every enemy within 8 metres."},
	"recklessness": {"name": "Recklessness", "cls": "warrior", "level": 32, "school": "physical", "cost": 0, "cd": 90.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "recklessness", "dmg_pct": 0.25, "haste": 0.2, "dur": 12.0, "anim": "Idle_Shield", "fx": "shout",
		"icon": ["♨", Color(1.0, 0.35, 0.2)], "desc": "For 12 seconds you deal 25% more damage and swing 20% faster."},
	"shield_wall": {"name": "Shield Wall", "cls": "warrior", "level": 40, "school": "physical", "cost": 0, "cd": 180.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "shield_wall", "dmg_taken": -0.5, "dur": 10.0, "anim": "Idle_Shield", "fx": "shout",
		"icon": ["⛨", Color(0.8, 0.8, 0.95)], "desc": "Halves the damage you take for 10 seconds."},
	"rallying_cry": {"name": "Rallying Cry", "cls": "warrior", "level": 50, "school": "physical", "cost": 0, "cd": 180.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "rallying_cry", "max_hp": [200, 30.0], "heal_pct": 0.2, "dur": 15.0, "anim": "Idle_Shield", "fx": "shout",
		"icon": ["⚑", Color(1.0, 0.85, 0.3)], "desc": "A shout that heals you for 20% of your health and raises it by {max_hp} for 15 seconds."},
	"cleaving_slam": {"name": "Cleaving Slam", "cls": "warrior", "level": 56, "school": "physical", "cost": 30, "cd": 12.0,
		"kind": "aoe", "radius": 9.0, "dmg": [40, 7.0], "slow_attack": 0.2, "dur": 8.0, "anim": "NinjaJump_Land", "fx": "thunderclap",
		"icon": ["☄", Color(1.0, 0.6, 0.3)], "desc": "Bring your weapon down so hard the ground splits: {dmg} damage to enemies within 9 metres, and their attacks slow by 20%."},

	# ------------------------------------------------------------------ Wizard
	"fireball": {"name": "Fireball", "cls": "wizard", "level": 1, "school": "fire", "cost": 7, "cast": 2.0,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [14, 6.2], "coef": 0.8, "burn": [2, 0.8], "burn_dur": 6.0, "speed": 22.0,
		"anim": "cast", "fx": "fireball", "icon": ["🔥", Color(1.0, 0.45, 0.1)],
		"desc": "Hurls a fiery ball that deals {dmg} Fire damage and burns for {burn} more over 6 seconds."},
	"frostbolt": {"name": "Frostbolt", "cls": "wizard", "level": 1, "school": "frost", "cost": 6, "cast": 1.8,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [11, 5.2], "coef": 0.7, "slow": 0.4, "slow_dur": 6.0, "speed": 26.0,
		"anim": "cast", "fx": "frostbolt", "icon": ["❄", Color(0.45, 0.8, 1.0)],
		"desc": "A bolt of ice dealing {dmg} Frost damage and slowing the target's movement by 40% for 6 seconds."},
	"fire_blast": {"name": "Fire Blast", "cls": "wizard", "level": 1, "school": "fire", "cost": 8, "cd": 8.0,
		"kind": "spell", "range": 20.0, "dmg": [12, 5.4], "coef": 0.43, "anim": "Spell_Simple_Shoot", "fx": "fire_blast",
		"icon": ["✹", Color(1.0, 0.6, 0.15)], "desc": "Blasts the enemy with fire for {dmg} damage. Instant."},
	"frost_nova": {"name": "Frost Nova", "cls": "wizard", "level": 1, "school": "frost", "cost": 7, "cd": 20.0,
		"kind": "aoe", "radius": 8.0, "dmg": [4, 1.2], "root": 6.0, "anim": "Spell_Simple_Shoot", "fx": "frost_nova",
		"icon": ["✳", Color(0.6, 0.9, 1.0)], "desc": "Blasts enemies within 8 metres for {dmg} Frost damage and freezes them in place for 6 seconds. Damage may break the ice."},
	"flamestrike": {"name": "Flamestrike", "cls": "wizard", "level": 1, "school": "fire", "cost": 14, "cast": 2.5, "cd": 6.0,
		"kind": "ground", "range": Rules.SPELL_RANGE, "radius": 5.0, "dmg": [16, 5.0], "coef": 0.6, "burn": [8, 2.8], "burn_dur": 8.0,
		"anim": "cast", "fx": "flamestrike", "icon": ["♨", Color(1.0, 0.35, 0.05)],
		"desc": "Calls a column of fire down on the target's position: {dmg} Fire damage to all enemies within 5 metres, then {burn} more over 8 seconds."},
	"arcane_missiles": {"name": "Arcane Missiles", "cls": "wizard", "level": 1, "school": "arcane", "cost": 9, "channel": 3.0, "ticks": 3,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [5, 2.2], "coef": 0.24, "speed": 30.0, "anim": "cast", "fx": "arcane_missile",
		"icon": ["✦", Color(0.85, 0.5, 1.0)], "desc": "Launches three Arcane Missiles over 3 seconds, each dealing {dmg} damage."},
	"frost_armor": {"name": "Frost Armor", "cls": "wizard", "level": 1, "school": "frost", "cost": 5,
		"kind": "buff", "self": true, "aura": "frost_armor", "armor": [30, 6.0], "dur": 1800.0, "anim": "Spell_Simple_Shoot", "fx": "frost_armor",
		"icon": ["⛨", Color(0.7, 0.9, 1.0)], "desc": "Coats you in frost: +{armor} armour for 30 minutes, and melee attackers are slowed."},
	"blink": {"name": "Blink", "cls": "wizard", "level": 1, "school": "arcane", "cost": 4, "cd": 15.0,
		"kind": "blink", "self": true, "dist": 12.0, "anim": "", "fx": "blink",
		"icon": ["⤳", Color(0.75, 0.55, 1.0)], "desc": "Teleports you 12 metres forward and frees you from roots and stuns."},

	"ice_barrier": {"name": "Ice Barrier", "cls": "wizard", "level": 16, "school": "frost", "cost": 12, "cd": 30.0, "self": true,
		"kind": "shield", "absorb": [60, 14.0], "dur": 60.0, "weakened": 0.1, "anim": "Spell_Simple_Shoot", "fx": "frost_armor",
		"icon": ["❆", Color(0.6, 0.85, 1.0)], "desc": "A shell of ice that absorbs {absorb} damage for a minute."},
	"pyroblast": {"name": "Pyroblast", "cls": "wizard", "level": 20, "school": "fire", "cost": 18, "cast": 4.0,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [40, 13.0], "coef": 1.15, "burn": [10, 3.0], "burn_dur": 8.0, "speed": 20.0, "anim": "cast", "fx": "fireball",
		"icon": ["☀", Color(1.0, 0.35, 0.05)], "desc": "A huge ball of fire that deals {dmg} Fire damage and burns for {burn} more. Slow to cast; best opened with."},
	"cone_of_cold": {"name": "Cone of Cold", "cls": "wizard", "level": 26, "school": "frost", "cost": 14, "cd": 10.0,
		"kind": "aoe", "radius": 8.0, "dmg": [18, 4.2], "coef": 0.2, "anim": "Spell_Simple_Shoot", "fx": "frost_nova",
		"icon": ["❄", Color(0.55, 0.85, 1.0)], "desc": "A blast of cold: {dmg} Frost damage to every enemy within 8 metres."},
	"arcane_power": {"name": "Arcane Power", "cls": "wizard", "level": 32, "school": "arcane", "cost": 0, "cd": 120.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "arcane_power", "dmg_pct": 0.3, "dur": 15.0, "anim": "Spell_Simple_Shoot", "fx": "blink",
		"icon": ["✧", Color(0.85, 0.55, 1.0)], "desc": "Your spells deal 30% more damage for 15 seconds."},
	"evocation": {"name": "Evocation", "cls": "wizard", "level": 40, "school": "arcane", "cost": 0, "cd": 240.0,
		"kind": "buff", "self": true, "aura": "evocation", "mana_regen": [40, 8.0], "dur": 8.0, "anim": "Spell_Simple_Shoot", "fx": "blink",
		"icon": ["◎", Color(0.6, 0.6, 1.0)], "desc": "Draw on the air around you: regain {mana_regen} mana a second for 8 seconds."},
	"meteor": {"name": "Meteor", "cls": "wizard", "level": 50, "school": "fire", "cost": 22, "cast": 3.0, "cd": 20.0,
		"kind": "ground", "range": Rules.SPELL_RANGE, "radius": 6.0, "dmg": [45, 11.0], "coef": 1.0, "burn": [14, 3.5], "burn_dur": 8.0,
		"anim": "cast", "fx": "flamestrike", "icon": ["☄", Color(1.0, 0.5, 0.1)], "desc": "Calls a burning rock down on the target: {dmg} Fire damage to all enemies within 6 metres, and {burn} more over 8 seconds."},
	"time_warp": {"name": "Time Warp", "cls": "wizard", "level": 56, "school": "arcane", "cost": 10, "cd": 300.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "time_warp", "haste": 0.3, "dur": 20.0, "anim": "Spell_Simple_Shoot", "fx": "blink",
		"icon": ["⧗", Color(0.7, 0.6, 1.0)], "desc": "Bend time: your spells cast 30% faster for 20 seconds."},

	# ------------------------------------------------------------------ Cleric
	"smite": {"name": "Smite", "cls": "cleric", "level": 1, "school": "holy", "cost": 6, "cast": 2.0,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [13, 5.8], "coef": 0.7, "undead": 1.5, "anim": "cast", "fx": "smite",
		"icon": ["☀", Color(1.0, 0.9, 0.5)], "desc": "Calls down holy light on an enemy for {dmg} Holy damage; half again against the undead."},
	"mend": {"name": "Mend", "cls": "cleric", "level": 1, "school": "holy", "cost": 6, "cast": 2.5, "helpful": true,
		"kind": "heal", "range": Rules.SPELL_RANGE, "heal": [30, 11.0], "coef": 0.85, "anim": "cast", "fx": "mend",
		"icon": ["✚", Color(1.0, 0.85, 0.35)], "desc": "Heals a friendly target (or you) for {heal}."},
	"renewal": {"name": "Renewal", "cls": "cleric", "level": 1, "school": "holy", "cost": 5, "helpful": true,
		"kind": "hot", "range": Rules.SPELL_RANGE, "total": [38, 13.0], "dur": 15.0, "tick": 3.0, "anim": "Spell_Simple_Shoot", "fx": "renewal",
		"icon": ["❀", Color(0.65, 1.0, 0.55)], "desc": "Heals the target for {total} over 15 seconds."},
	"ward_of_light": {"name": "Ward of Light", "cls": "cleric", "level": 1, "school": "holy", "cost": 7, "cd": 4.0, "helpful": true,
		"kind": "shield", "range": Rules.SPELL_RANGE, "absorb": [30, 9.5], "dur": 30.0, "weakened": 15.0, "anim": "Spell_Simple_Shoot", "fx": "ward",
		"icon": ["◈", Color(1.0, 0.95, 0.7)], "desc": "Surrounds a friend with light that absorbs {absorb} damage for 30 seconds. The same soul cannot be warded again for 15 seconds."},
	"shadow_rot": {"name": "Shadow Rot", "cls": "cleric", "level": 1, "school": "shadow", "cost": 7,
		"kind": "dot", "range": Rules.SPELL_RANGE, "total": [24, 8.5], "coef": 1.0, "dur": 18.0, "tick": 3.0, "anim": "Spell_Simple_Shoot", "fx": "shadow_rot",
		"icon": ["☾", Color(0.65, 0.35, 0.95)], "desc": "A creeping shadow that deals {total} Shadow damage over 18 seconds."},
	"holy_nova": {"name": "Holy Nova", "cls": "cleric", "level": 1, "school": "holy", "cost": 16, "cd": 10.0,
		"kind": "aoe", "radius": 10.0, "dmg": [6, 1.8], "heal": [10, 3.0], "anim": "Spell_Simple_Shoot", "fx": "holy_nova",
		"icon": ["✺", Color(1.0, 0.95, 0.6)], "desc": "A burst of light from you: {dmg} Holy damage to enemies within 10 metres and {heal} healing to you and your friends."},
	"inner_fire": {"name": "Inner Fire", "cls": "cleric", "level": 1, "school": "holy", "cost": 5,
		"kind": "buff", "self": true, "aura": "inner_fire", "armor": [60, 10.0], "ap": [6, 1.2], "dur": 600.0, "anim": "Spell_Simple_Shoot", "fx": "inner_fire",
		"icon": ["♆", Color(1.0, 0.7, 0.3)], "desc": "A holy fire within you: +{armor} armour and +{ap} attack power for 10 minutes."},

	"resurrection": {"name": "Resurrection", "cls": "cleric", "level": 20, "school": "holy", "cost": 30, "cast": 6.0, "helpful": true, "dead_ok": true,
		"kind": "res", "range": Rules.SPELL_RANGE, "anim": "cast", "fx": "mend", "icon": ["✞", Color(1.0, 0.95, 0.75)],
		"desc": "Brings a dead friend back to life with some of their health and mana. Out of combat only.", "ooc": true},
	"greater_mend": {"name": "Greater Mend", "cls": "cleric", "level": 14, "school": "holy", "cost": 12, "cast": 3.0, "helpful": true,
		"kind": "heal", "range": Rules.SPELL_RANGE, "heal": [75, 21.0], "coef": 1.2, "anim": "cast", "fx": "mend",
		"icon": ["✙", Color(1.0, 0.9, 0.45)], "desc": "A slow, deep heal: restores {heal} health to a friend."},
	"mind_blast": {"name": "Mind Blast", "cls": "cleric", "level": 20, "school": "shadow", "cost": 10, "cast": 1.5, "cd": 8.0,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [22, 7.0], "coef": 0.43, "anim": "cast", "fx": "smite",
		"icon": ["☾", Color(0.75, 0.4, 1.0)], "desc": "Blasts the target's mind for {dmg} Shadow damage."},
	"prayer_of_healing": {"name": "Prayer of Healing", "cls": "cleric", "level": 26, "school": "holy", "cost": 18, "cd": 6.0, "helpful": true,
		"kind": "aoe", "radius": 14.0, "heal": [40, 9.0], "anim": "Spell_Simple_Shoot", "fx": "holy_nova",
		"icon": ["✾", Color(1.0, 0.95, 0.6)], "desc": "A prayer for everyone near you: heals you and friends within 14 metres for {heal}."},
	"divine_protection": {"name": "Divine Protection", "cls": "cleric", "level": 32, "school": "holy", "cost": 5, "cd": 120.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "divine_protection", "dmg_taken": -0.4, "dur": 8.0, "anim": "Spell_Simple_Shoot", "fx": "inner_fire",
		"icon": ["☼", Color(1.0, 0.95, 0.7)], "desc": "The Ember shelters you: you take 40% less damage for 8 seconds."},
	"radiance": {"name": "Radiance", "cls": "cleric", "level": 40, "school": "holy", "cost": 12, "helpful": true, "cd": 8.0,
		"kind": "hot", "range": Rules.SPELL_RANGE, "total": [110, 27.0], "dur": 12.0, "tick": 2.0, "anim": "Spell_Simple_Shoot", "fx": "renewal",
		"icon": ["✹", Color(1.0, 0.9, 0.5)], "desc": "Bathes a friend in light, healing {total} over 12 seconds."},
	"holy_fire": {"name": "Holy Fire", "cls": "cleric", "level": 50, "school": "holy", "cost": 14, "cast": 2.0, "cd": 10.0,
		"kind": "spell", "range": Rules.SPELL_RANGE, "dmg": [30, 10.0], "coef": 0.75, "burn": [12, 3.0], "burn_dur": 8.0, "undead": 1.25, "anim": "cast", "fx": "smite",
		"icon": ["♨", Color(1.0, 0.75, 0.3)], "desc": "Holy flame: {dmg} Holy damage, and {burn} more over 8 seconds."},
	"salvation": {"name": "Salvation", "cls": "cleric", "level": 56, "school": "holy", "cost": 20, "cd": 60.0, "helpful": true,
		"kind": "heal", "range": Rules.SPELL_RANGE, "heal": [120, 24.0], "coef": 1.5, "anim": "Spell_Simple_Shoot", "fx": "mend",
		"icon": ["✚", Color(1.0, 1.0, 0.8)], "desc": "An instant, great heal: restores {heal} health to a friend."},

	# ------------------------------------------------------------------ monsters
	# ------------------------------------------------------------------ everyone
	"myth_quake": {"name": "Worldbreaker", "cls": "all", "level": 60, "school": "physical", "cost": 0, "cd": 120.0, "gcd": false,
		"kind": "aoe", "radius": 10.0, "dmg": [300, 30.0], "anim": "NinjaJump_Land", "fx": "thunderclap", "icon": ["☄", Color(1.0, 0.55, 0.1)],
		"desc": "Split the earth: {dmg} damage to every enemy within 10 metres."},
	"myth_hours": {"name": "Stop the Hours", "cls": "all", "level": 60, "school": "arcane", "cost": 0, "cd": 180.0, "gcd": false,
		"kind": "buff", "self": true, "aura": "myth_hours", "haste": 1.0, "free_cast": 1.0, "dur": 10.0, "anim": "Spell_Simple_Shoot", "fx": "blink", "icon": ["⧗", Color(1.0, 0.6, 0.2)],
		"desc": "Your spells cost nothing and cast twice as fast for 10 seconds."},
	"myth_dawn": {"name": "Second Sunrise", "cls": "all", "level": 60, "school": "holy", "cost": 0, "cd": 180.0, "gcd": false, "helpful": true,
		"kind": "aoe", "radius": 30.0, "heal": [0, 0.0], "heal_pct": 0.33, "anim": "Spell_Simple_Shoot", "fx": "holy_nova", "icon": ["☀", Color(1.0, 0.7, 0.2)],
		"desc": "Heals you and everyone near you for a third of their health."},
	"summon_stag": {"name": "Highland Stag", "cls": "all", "level": 40, "school": "nature", "cost": 0, "cast": 1.5, "self": true, "ooc": true,
		"kind": "mount", "anim": "cast", "fx": "", "icon": ["♞", Color(0.7, 0.55, 0.35)], "desc": "Summons your Highland Stag. Riding, you move 60% faster. Anything you do other than walk gets you off."},

	"hearthstone": {"name": "Hearthstone", "cls": "all", "level": 1, "school": "arcane", "cost": 0, "cast": 10.0, "cd": 3600.0, "self": true,
		"kind": "hearth", "anim": "cast", "fx": "blink", "icon": ["⌂", Color(0.4, 0.8, 1.0)],
		"desc": "Returns you to your home inn after 10 seconds. Moving or being hit stops it."},
	"ember_bolt": {"name": "Ember Bolt", "cls": "monster", "level": 1, "school": "fire", "cost": 0, "cast": 2.2,
		"kind": "spell", "range": 26.0, "dmg": [5, 2.3], "speed": 16.0, "anim": "cast", "fx": "fireball", "icon": ["🔥", Color(1, 0.5, 0.1)], "desc": ""},
	"ravage": {"name": "Ravage", "cls": "monster", "level": 1, "school": "physical", "cost": 0, "cd": 12.0,
		"kind": "dot", "range": Rules.MELEE_RANGE, "total": [12, 4.0], "dur": 12.0, "tick": 3.0, "anim": "Zombie_Scratch", "fx": "rend", "icon": ["✂", Color(0.8, 0.2, 0.2)], "desc": ""},
	"tidal_slam": {"name": "Tidal Slam", "cls": "monster", "level": 1, "school": "frost", "cost": 0, "cd": 14.0, "cast": 2.0,
		"kind": "telegraph", "range": 20.0, "radius": 5.0, "dmg": [30, 6.0], "anim": "Sword_Attack", "fx": "tidal_slam", "icon": ["❄", Color(0.4, 0.7, 1.0)], "desc": ""},
	"hellfire_ring": {"name": "Hellfire", "cls": "monster", "level": 1, "school": "fire", "cost": 0, "cd": 16.0, "cast": 2.5,
		"kind": "telegraph", "self_center": true, "radius": 8.0, "dmg": [35, 7.0], "anim": "Sword_Heavy_Combo", "fx": "hellfire", "icon": ["🔥", Color(1, 0.3, 0.05)], "desc": ""},
	"arrow_shot": {"name": "Shoot", "cls": "monster", "level": 1, "school": "physical", "cost": 0, "cast": 1.6,
		"kind": "spell", "range": 30.0, "dmg": [10, 3.2], "speed": 34.0, "anim": "Spell_Simple_Shoot", "fx": "arcane_missile", "icon": ["➶", Color(0.8, 0.7, 0.5)], "desc": ""},
	"bog_bolt": {
"name": "Bog Bolt", "cls": "monster", "level": 1, "school": "nature", "cost": 0, "cast": 2.2,
		"kind": "spell", "range": 30.0, "dmg": [10, 3.0], "speed": 18.0, "anim": "Spell_Simple_Shoot", "fx": "ember_bolt", "icon": ["☄", Color(0.4, 0.8, 0.3)], "desc": ""},
	"brine_bolt": {"name": "Brine Bolt", "cls": "monster", "level": 1, "school": "frost", "cost": 0, "cast": 2.2,
		"kind": "spell", "range": 30.0, "dmg": [10, 3.0], "speed": 20.0, "anim": "Spell_Simple_Shoot", "fx": "frostbolt", "icon": ["❄", Color(0.4, 0.7, 1.0)], "desc": ""},
	"frost_lance": {"name": "Frost Lance", "cls": "monster", "level": 1, "school": "frost", "cost": 0, "cast": 2.0,
		"kind": "spell", "range": 30.0, "dmg": [10, 3.1], "slow": 0.3, "slow_dur": 5.0, "speed": 26.0, "anim": "cast", "fx": "frostbolt", "icon": ["❄", Color(0.6, 0.9, 1.0)], "desc": ""},
	"void_bolt": {"name": "Void Bolt", "cls": "monster", "level": 1, "school": "shadow", "cost": 0, "cast": 2.2,
		"kind": "spell", "range": 30.0, "dmg": [11, 3.2], "speed": 22.0, "anim": "cast", "fx": "arcane_missile", "icon": ["✦", Color(0.7, 0.4, 1.0)], "desc": ""},
	"magma_spit": {"name": "Magma Spit", "cls": "monster", "level": 1, "school": "fire", "cost": 0, "cd": 12.0, "cast": 1.8,
		"kind": "telegraph", "range": 22.0, "radius": 4.0, "dmg": [28, 6.0], "anim": "Sword_Attack", "fx": "hellfire", "icon": ["🔥", Color(1, 0.4, 0.1)], "desc": ""},
	"glacial_nova": {"name": "Glacial Nova", "cls": "monster", "level": 1, "school": "frost", "cost": 0, "cd": 18.0, "cast": 2.5,
		"kind": "telegraph", "self_center": true, "radius": 9.0, "dmg": [36, 7.0], "anim": "Sword_Heavy_Combo", "fx": "tidal_slam", "icon": ["❄", Color(0.6, 0.9, 1.0)], "desc": ""},
	"void_nova": {"name": "Void Nova", "cls": "monster", "level": 1, "school": "shadow", "cost": 0, "cd": 18.0, "cast": 2.5,
		"kind": "telegraph", "self_center": true, "radius": 8.0, "dmg": [34, 7.0], "anim": "Sword_Heavy_Combo", "fx": "hellfire", "icon": ["✦", Color(0.6, 0.3, 1.0)], "desc": ""},
	"pyre_nova": {"name": "Pyre Nova", "cls": "monster", "level": 1, "school": "fire", "cost": 0, "cast": 3.0, "gcd": false,
		"kind": "telegraph", "self_center": true, "radius": 11.0, "dmg": [60, 12.0], "anim": "Sword_Heavy_Combo", "fx": "hellfire", "icon": ["🔥", Color(1, 0.3, 0.05)], "desc": ""},
	"colossus_stomp": {"name": "Stomp", "cls": "monster", "level": 1, "school": "fire", "cost": 0, "cast": 2.0, "gcd": false,
		"kind": "telegraph", "self_center": true, "radius": 8.0, "dmg": [120, 26.0], "anim": "Sword_Heavy_Combo", "fx": "hellfire", "icon": ["☄", Color(1, 0.4, 0.1)], "desc": ""},
	"vaal_nova": {"name": "Void Nova", "cls": "monster", "level": 1, "school": "shadow", "cost": 0, "cast": 2.5, "gcd": false,
		"kind": "telegraph", "self_center": true, "radius": 13.0, "dmg": [140, 30.0], "anim": "Sword_Heavy_Combo", "fx": "hellfire", "icon": ["✦", Color(0.6, 0.3, 1.0)], "desc": ""},
	"grub_eruption": {
"name": "Eruption", "cls": "monster", "level": 1, "school": "nature", "cost": 0, "cast": 2.6, "gcd": false,
		"kind": "telegraph", "radius": 4.5, "dmg": [30, 8.0], "range": 99.0, "anim": "", "fx": "", "icon": ["☄", Color(0.6, 0.5, 0.3)], "desc": ""},
}


## the five each class starts with on the bar, in key order 1–5
const DEFAULT_BAR := {
	"warrior": ["heroic_strike", "charge", "rend", "thunder_clap", "execute"],
	"wizard": ["fireball", "frostbolt", "fire_blast", "frost_nova", "flamestrike"],
	"cleric": ["smite", "mend", "renewal", "ward_of_light", "shadow_rot"],
}

static func for_class(cls: String) -> Array:
	var out := []
	for id in LIST:
		if LIST[id]["cls"] == cls: out.append(id)
	return out

## a magnitude such as "dmg" at the caster's level plus its share of power
static func value(id: String, key: String, level: int, power := 0.0) -> float:
	var a: Dictionary = LIST[id]
	if not a.has(key): return 0.0
	var v = a[key]
	var base: float = float(v[0]) + float(v[1]) * level if v is Array else float(v)
	return base + power * float(a.get("coef", 0.0))

## the ability's description with its numbers filled in for this level
static func describe(id: String, level: int, power := 0.0) -> String:
	var a: Dictionary = LIST[id]
	var s: String = a["desc"]
	for key in ["bonus", "total", "dmg", "burn", "heal", "absorb", "ap", "armor"]:
		if s.contains("{" + key + "}"): s = s.replace("{" + key + "}", str(int(round(value(id, key, level, power)))))
	return s

static func cost_text(id: String, power_kind: String, base_mp: int) -> String:
	var a: Dictionary = LIST[id]
	var c := int(a.get("cost", 0))
	if c < 0: return "Generates %d Rage" % -c
	if c == 0: return ""
	if power_kind == "rage": return "%d Rage" % c
	return "%d Mana" % int(round(base_mp * c / 100.0 * 0.6))
