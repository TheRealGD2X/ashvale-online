# Ashvale Online — Design Bible

*Owner: GD2X. Written by the art/presentation worker (Claude) as the shared source of truth for every worker on the project. If code and this document disagree, this document wins until it is changed here.*

**One line:** Classic World of Warcraft's heart in a Legend of Mir 2 body — a single-player MMORPG with a living cast of characters, played top-down, that gives back the more you play.

---

## 0. How to read this

Section 1 is the vision; everything else serves it. Sections 2–9 are the rules of the game and are written for the **systems worker** (who builds `src/sim/`). Section 10 is what the systems must expose to the **presentation worker** (who builds `src/view/`). Section 11 is the build order. Numbers in this document are starting values for tuning, not scripture — but change them here, not silently in code.

The current build (`index.html`) is the *first draft* this replaces. It is useful as a reference for what already exists (five maps, three classes, 76 items, 34 monsters, six bosses, a bot layer with personalities, a quest chain, guilds, storage, a blacksmith), but the combat model, the loot rules, the progression and the bots described here are deliberately different from what it does today.

---

## 1. Vision and pillars

### The fantasy
You log into a small, warm fantasy world that has been running without you. People are shouting in town. Someone in your guild says "wb". Your rested bar is full because you slept at the inn. There's a dungeon you need one more piece from, a boss you've heard is up, a friend who said they'd run the Mine with you tonight. You play for forty minutes or four hours, and either way you log out with something moved forward and something still to chase.

### Six pillars — every feature must serve at least one

1. **The world keeps moving without you.** Bots level, guilds recruit, bosses respawn, the day turns, on the real clock. Logging in should feel like walking back into a room where a conversation was already happening.
2. **Rhythm, not reflex.** Combat is tab-target, auto-attack and a global cooldown. Satisfaction comes from pressing the right ability at the right moment, watching a proc light up, landing the interrupt. Nothing requires fast clicking.
3. **Everything gives back.** Every kill ranks an ability, fills a reputation, or moves a quest. There is always something you can finish tonight and something bigger you can see but can't have yet.
4. **Danger is real and groups are the answer.** An even-level monster is a fight; two are a risk; an elite needs friends. Tank, healer and damage are real roles with real mechanics, not chat lines.
5. **Loot is rare, visible and a story.** Good items come from specific bosses, drop rarely, show on your character, and arrive through a need/greed roll with people you know. Nobody forgets their first purple.
6. **Cozy.** Warm colours, unhurried pacing, kind writing, no pressure timers outside of raid bosses (lockouts and roll windows are not pressure; enrage timers are, and only raid bosses have them), music you can leave on for hours, an inn that feels like home. Challenge lives in the fights, never in the menus.

### What this is not
Not Diablo (no screens full of loot, no build-crafting with a thousand affixes), not an idle game (nothing progresses without your presence except the *world*), not a story game (the story is what happened to *you* on this server), not an online game (there is no network code, ever).

---

## 2. Sessions: what a good day looks like

**A 30-minute evening.** Log in at the inn. Rested XP is up. Guild chat says hi. Check the daily board: "Clear the Hollow Mine" and "Kill 12 Marsh Stalkers". Someone shouts "LF1M Mine, need healer". Whisper them, get invited, run the Mine with four people whose names you know, need on the belt that drops, win it, equip it. Log out at the inn.

**A long Saturday.** The weekly raid lockout reset this morning. Your guild's raid leader whispered last night: "Sanctum Saturday 2pm, you're main tank". Spend the morning finishing the Mirewood reputation chain for the Honored trinket, catch a rare spawn someone shouted about, sell the greens you don't need to a bot who's been WTB-ing bracelets. At two, nine people gather at the Sanctum gate, someone's late, someone forgot food, you pull. Four bosses, two wipes, one Mythic drop that goes to the wizard who's been raiding for three weeks and everyone is happy for her. Server-first message in yellow. Bed.

Both sessions had: a reason to log in (rested XP, lockout, an invitation), a social moment (chat, group, roll), a reward you could see (equip), and a hook for next time (the trinket, the piece that didn't drop).

---

## 3. Combat model

### 3.1 Targeting and auto-attack
- **Target** with Tab (cycles nearest hostile in view, closest first), click, or Space (nearest hostile). Targeting a friendly (bot, NPC, pet) is allowed and drives heals.
- **Auto-attack** starts when you press Attack (or any damaging ability) with a hostile target and continues on a weapon-speed timer until the target dies, you press Stop, or you target something else. Melee range = adjacent tile (8 directions). Ranged/spell range = 8 tiles with line of sight. Out of range: auto-attack pauses (UI shows red range indicator), it resumes when in range.
- **Movement** is WASD (8-way, tile-based with smooth interpolation). Click-to-move remains as an option. Moving does not cancel auto-attack; it cancels *casts*.
- **Facing** matters only for parry (you can't parry attacks from behind) and for monster "cleave" cones.

### 3.2 The global cooldown
Every ability triggers a **1.5 s global cooldown (GCD)**. Instants share it, casts share it (the GCD runs from cast start). Off the GCD: potions, food, stance switching, Taunt-class "oh no" buttons marked `offGcd` in the ability table. This single rule gives combat its tempo and makes the hotbar feel like an instrument.

### 3.3 Casting
- Cast abilities have a cast time (1.5–3 s). A cast bar is shown. Moving cancels. Taking damage adds **pushback** (+0.5 s, max twice per cast). An **interrupt** cancels the cast and locks that spell school for 4 s.
- Channelled abilities (Ice Storm, Meditation) tick while you stand still; damage does not cancel them, movement does.

### 3.4 Resources
| Class | Resource | Rule |
|---|---|---|
| Warrior | **Rage** 0–100 | Gain `15 × dmg / avgWhiteHit(lv)` per auto-attack hit (so an average hit = 15 rage, a crit ≈ 22), where `avgWhiteHit(lv) = 8 + 2.2·lv` (the expected white hit of a Warrior in level-appropriate gear; see §12). +1 rage per 1 % of max HP taken as damage. Decays 3/s starting 5 s after leaving combat. Starts at 0. |
| Wizard | **Mana** | Pool from Intellect (§12). Regen = `Spirit × 0.05` per second, **paused for 3 s after any cast** (the "five-second rule", shortened). Out of combat and not casting: ×2. |
| Taoist | **Mana** | Same rule. Taoist has more Spirit; healing is a mana-management game. |

**Mana costs are a percentage of max MP** (listed per ability in §4), so the resource game holds at every level. A Taoist chain-casting Healing spends ~2.8 % of the pool per second against ~0.3 %/s regen: roughly 40 s of continuous healing before the bar is empty. That is the tension.

**Potions** (HP and MP) share a **120 s cooldown** and restore a fixed amount by tier (§12). Instant-effect potions do not bypass it. This is the single biggest change from the first draft and it is not negotiable: unlimited healing makes every other system meaningless. The **belt** is the quick-use bar for consumables (Q and E drink the first two slots); it has 4 slots at level 1 and 6 from level 20.

**Food and drink**: usable out of combat, restore HP/MP over 20 s while sitting, grant *Well Fed* (+small stat) for 30 min if you finish. Sitting is a real state (view draws it; bots do it). Eating in town with people is cozy on purpose.

### 3.5 Stats
Keep Mir's displayed numbers because GD2X loves them, and derive them from WoW-style base attributes so items and levels are comparable.

Base attributes: **Strength, Agility, Stamina, Intellect, Spirit**. Derived (shown on the character sheet in Mir terms):
- **DC** (melee damage range) = weapon damage + Strength/10 … Strength/6
- **MC** (magic damage) = Intellect/8 … Intellect/5 + spellpower
- **SC** (spirit/holy damage & healing power) = Spirit/8 … Spirit/5 + healpower
- **AC** (armour) from gear + Agility×2 → physical damage reduction `DR = AC / (AC + 400 + 85·attackerLevel)`, capped 75 %
- **MAC** (magic resist) from gear → magic reduction `MR = MAC / (MAC + 100 + 15·attackerLevel)`, capped 50 %. MAC applies to every non-physical school; items may add school-specific resist on top.
- **Schools**: Physical, Fire, Frost, Nature, Holy, Shadow. Every ability carries one (§4 tables). Monsters use Physical, Fire, Nature (poison), Shadow (undead/cultists). Interrupts lock the school of the spell that was interrupted.
- **HP** = `hpBase(lv, class) + Stamina×10`. **MP** = `mpBase(lv, class) + Intellect×15`. Base tables in §12.
- **Crit** = 5 % + Agility/20 (melee) or Intellect/20 (spell); crits deal ×1.5 (heals too). **Dodge** = 5 % + Agility/25. **Parry** 5 % (Warrior only, front only). **Hit** 95 % base vs same level, −1 % per level the target is above you. Monsters: 5 % dodge, 5 % crit ×1.5, no parry (bosses 10 % parry from the front — another reason the tank faces it and DPS stand behind).

### 3.6 The hit table (melee)
One roll: Miss → Dodge → Parry → Crit → Hit (block is not used; Warriors have no shield). Spells: Miss (resist-all) → Crit → Hit; partial resists are not used (keep it readable).

### 3.7 Threat
Every monster keeps a **threat table** `{ [entityId]: threat }`.
- Damage adds threat = damage × modifiers. Healing adds 0.5 × amount healed (overheal excluded), split across every monster in combat with the healer. Abilities that do no damage carry a **flat threat** value in their table entry (Sunder: `60 + 3·lv` on the target; party buffs: 10 per monster in combat).
- Warrior Defensive Stance ×1.3. Abilities carry their own multiplier where listed (Heroic Strike ×1.5 of its damage, Revenge ×2.5). Ranged/spell damage ×1.0 but see the switch rule. Pets generate threat like any attacker.
- **Switch rule:** a monster changes target when someone's threat exceeds the current target's by **10 % (melee range)** or **30 % (ranged)**. This is what lets the tank hold aggro if DPS waits a few seconds. The view gets `combat:threat` when aggro moves.
- **Taunt** sets the caster's threat to `top × 1.1` and forces the target for 3 s. Bosses can be taunted (Classic) unless flagged `noTaunt`.
- Threat wipes on death, on leaving combat, and on **leash** (monster returns home at full HP if it travels more than 25 tiles from spawn, immune while returning).

### 3.8 Monsters
- **Con colours** by level difference: grey (≥8 below you: no XP), green, yellow (even), orange (+3), red (≥+5). Hit chance and XP scale with the difference; grey mobs give no XP or reputation (so you move on — this is a pillar) but still drop junk, quest items and turn-in materials.
- **Types:** beast, humanoid, undead, demon, elemental. Affects abilities (Holy Bind works on undead, Hex on beast/humanoid), loot (humanoids drop gold and cloth), and sounds.
- **Behaviours** (flags on `MON`): `aggro` radius (0 = passive), `social` (pack aggro within 6 tiles), `caster` (holds range 6, casts, low HP — kill first), `healer` (heals its pack — interrupt), `flees` (humanoids run at 20 % HP and pull friends), `patrol` path, `charger`, `cleave` (front cone), `poison`/`disease` (needs Purify), `stealth` (visible only within 3 tiles).
- **Elites** (silver dragon frame): 2.5× HP, 1.5× damage, immune to Hex, drop uncommon+ always. Meant for groups of 2–3 or a 5-man dungeon.
- **Rare spawns** (silver star): unique named monsters with a 1–3 h respawn window, one per zone band; always drop a blue; bots shout when they see one. This is the "you never know" hook.
- **Bosses** (gold frame): section 7.
- **Speed:** player base speed is **4 tiles/s** (0.25 s per tile). Monsters move at 100 % of player speed while their target is within 4 tiles, 80 % otherwise; bosses 110 % within 4 tiles. You can *escape* with a head start; you cannot *kite forever*. Casters and ranged monsters make kiting costly. Slows are short (≤3 s) and roots have cooldowns.
- **Control immunity:** bosses (gold frame) are immune to roots, stuns, fears, Hex and slows; elites are immune to Hex. Taunt works on everything unless flagged `noTaunt`.

### 3.9 Death
1. You die: `player:death`. Screen desaturates. A **Release** button appears (auto after 30 s).
2. Release → you are a **ghost at the zone's graveyard** (each zone has one, near the hub). You can walk to your corpse (marked on the map) and **Revive** there with 50 % HP/MP, no other penalty except **10 % durability loss** on all gear.
3. Or talk to the **Spirit Healer** at the graveyard to revive immediately with **Resurrection Sickness** (−50 % all stats, 1 min per level over 10, max 5 min) and 25 % durability loss.
4. In a group, a Taoist can **Resurrect** you where you fell (out of combat).
Death costs time, gold (repair) and a little dignity — Classic's exact recipe. No XP loss.

### 3.10 Durability and repair
Every gear item has durability (100). Loses 1 per minute of combat (armour) or per ~50 hits (weapons), 10 % on corpse-revive, 25 % on Spirit Healer. At 0 the item gives no stats (still shows). Repair at any blacksmith for gold scaled by item level. This is the primary **gold sink** and the reason gold from bots matters.

---

## 4. Classes

Three classes, Mir names, WoW kits. Every ability is learned from the class trainer in Ashvale at the listed level for a small gold cost. **Ranks:** an ability is rank 1 when learned and reaches ranks 2–5 **by use** (at 30 / 90 / 220 / 500 uses). Each rank adds **+6 % potency** (damage, healing, absorb, or duration for buffs; for utility abilities such as Taunt, Teleport and Purify the rank instead cuts the cooldown by 4 %) and, for the view, a bigger visual and sound. Rank 5 on a favourite ability takes hours — that's the point.

Abilities marked ★ are the **defining** ability at a milestone level (the door that opens). `cd` = cooldown; everything is on the GCD unless marked `offGcd`. Mana costs are **% of max MP**. Schools: Warrior abilities are Physical except Flaming Sword (Fire); Wizard: Fire (Fireball, Ember, Fire Wall, Hellfire, Sunburst), Frost (Frost Bolt, Frost Ring, Ice Storm, Frost Cocoon), Nature (Thunder), Arcane-free utility (Teleport, Silence Rune, Clarity, Meditation, Hex = Nature); Taoist: Holy (all heals, Soul Fire, Judgement, Ward, Sanctuary, Resurrection, Guardian Spirit), Nature (Poison), Shadow (Summon Skeleton, Holy Bind counts as Holy).

**Pets** (Taoist): stances Passive / Defensive (default in a party) / Aggressive (default solo); `Dismiss`. The Skeleton's auto-taunt only fires in Aggressive stance, so it never rips a boss off a tank by accident. One pet at a time; Shinsu and Skeleton are a choice, not a replacement.

**Buff stacking:** one buff per category — *shout* (War Cry), *blessing* (Blessing), *ward* (Magic Shield, Ward), *aura* (Soul Shield, Clarity). A stronger rank replaces a weaker one.

### 4.1 Warrior — tank / melee damage. Resource: Rage.
Stances (offGcd, 1 s cd, switching keeps rage): **Battle** (default) · **Defensive** (lv 10): −10 % damage dealt, −10 % taken, threat ×1.3, enables Taunt/Revenge/Iron Guard.

| Lv | Ability | Cost | cd | Effect |
|---|---|---|---|---|
| 1 | Heroic Strike | 15 rage | – | Next auto-attack deals +DC×0.6 and ×1.5 threat. Queues on the swing. |
| 4 | Shoulder Dash | +10 rage | 15 s | Rush a target 3–8 tiles away, 1 s stun. |
| 6 | Rend | 10 | – | Bleed: DC×0.8 over 12 s. Does not stack; refreshes. |
| 8 | Half Moon | 20 | 6 s | Strike all adjacent enemies for DC×0.7; −10 % attack speed 10 s. Tank's pack tool. |
| 10 | **★ Taunt** | – | 10 s, offGcd | Threat = top×1.1, forces target 3 s. Defensive only. |
| 12 | Sunder Armour | 12 | – | −8 % AC per stack, max 5, 30 s. No damage; flat threat `60 + 3·lv`. |
| 14 | Revenge | 5 | 5 s | Usable for 5 s after you dodge/parry. DC×1.0, threat ×2.5. **Lights up** (`ability:ready`). |
| 16 | Iron Guard | 10 | 30 s, offGcd | +40 % parry for 6 s. Defensive only. |
| 18 | Pommel Strike | 10 | 12 s | Interrupt, silence 2 s. |
| 20 | War Cry | 10 | – | Party +10 % DC/MC/SC for 2 min. |
| 22 | Execute | 15 (+all) | – | Target < 20 % HP: DC×2 + 0.1×DC per extra rage. |
| 24 | Flaming Sword | 25 | 10 s | DC×1.8 + fire DC×0.6. The Mir signature — big visual. |
| 26 | Berserk | – | 60 s, offGcd | Gain 20 rage now, +10 over 10 s; costs 10 % HP. |
| 28 | Terrify | 25 | 3 min | Fear all adjacent 4 s. Panic button. |
| 30 | Last Bastion | – | 5 min, offGcd | −60 % damage taken 10 s. |
| 34 | Crippling Blow | 30 | 6 s | DC×2.2; target −20 % damage dealt 10 s. |
| 38 | Hurricane | 25 | 10 s | DC×1.0 to all within 2 tiles. |
| 40 | Undying | – | 10 min, offGcd | +30 % max HP for 20 s. |

Rotation feel: build rage on white hits → Sunder ×5 → Heroic Strike dumps → Revenge when lit → Half Moon on packs → Taunt when a caster rips → Execute at 20 %. DPS in Battle Stance uses Rend/Flaming Sword/Crippling Blow.

### 4.2 Wizard — ranged damage / control. Resource: Mana. Schools: Fire, Frost, Nature.
| Lv | Ability | Cost | cd | Effect |
|---|---|---|---|---|
| 1 | Fireball | 7 % | – | 2.5 s cast. MC×2.2 fire + MC×0.3 burn over 4 s. The filler. |
| 4 | Frost Bolt | 6 % | – | 2.0 s cast. MC×1.5 frost, −40 % move for **3 s**. |
| 6 | Ember | 5 % | 8 s | Instant MC×1.1 fire. |
| 8 | Thunder | 9 % | 6 s | 2.0 s cast. MC×2.4 nature, ×1.5 vs undead. The big hit, not the filler. |
| 10 | **★ Frost Ring** | 6 % | 25 s | Root all adjacent 6 s (breaks on damage after 2 s). |
| 12 | Magic Shield | 10 % | 90 s | Absorb MC×6 for 30 s. |
| 14 | Teleport | 5 % | 20 s | Blink 5 tiles in facing direction. |
| 16 | Fire Wall | 11 % | 15 s | Ground fire 3×1 tiles, MC×0.5/s for 8 s. |
| 18 | Silence Rune | 4 % | 24 s | Interrupt, lock school 4 s. |
| 20 | Clarity | 5 % | – | Party +10 % max MP, +2 % spell crit, 30 min. |
| 22 | Ice Storm | 15 % | 30 s | Channel 6 s: MC×0.6/s to all in 3-tile radius, −30 % move. |
| 24 | Meditation | – | 5 min | Channel 8 s: restore 60 % mana. |
| 26 | Hex | 7 % | 20 s | 1.5 s cast. Turn a beast/humanoid into a hen for 20 s; breaks on damage. One target at a time. |
| 30 | Hellfire | 20 % | 30 s | MC×3 fire to all within 2 tiles, self −10 % HP. |
| 34 | Frost Cocoon | – | 5 min, offGcd | Immune 8 s, can't act. |
| 38 | Sunburst | 22 % | 20 s | 5 s cast. MC×5 fire. |
| 40 | Overload | – | 3 min, offGcd | Next 3 spells crit. |

Rotation feel: Frost Bolt for the slow when something is coming, Fireball as the filler, Thunder and Ember on cooldown, Frost Ring + Teleport when something reaches you, Hex the second mob, Silence the caster. Mana is the limiter; Meditation is the reset. With a 3 s slow and monsters at full speed inside 4 tiles, a Wizard *can* buy a cast or two but cannot kite a mob to death — that is intended.

### 4.3 Taoist — healer / support / pet class. Resource: Mana. Schools: Holy (SC), Nature.
| Lv | Ability | Cost | cd | Effect |
|---|---|---|---|---|
| 1 | Healing | 7 % | – | 2.5 s cast. Heal SC×2.5. |
| 4 | Poison | 5 % | – | Nature DoT: SC×1.2 over 12 s. |
| 6 | Soul Fire | 6 % | – | 1.5 s cast. SC×1.6 holy. The solo button. |
| 8 | Spirit Mend | 5 % | – | Instant HoT: SC×1.8 over 15 s. |
| 10 | **★ Summon Skeleton** | 15 % | 60 s | Pet: tank-type, HP = 60 % of yours, taunts every 8 s in Aggressive stance. Persists until dismissed or killed. |
| 12 | Soul Shield | 6 % | – | Party +15 % AC/MAC, 10 min. |
| 14 | Quick Mend | 11 % | – | 1.5 s cast. Heal SC×1.6. Expensive. |
| 16 | Purify | 4 % | 8 s | Remove poison/disease/curse (and boss drains flagged `dispellable`) from target. |
| 18 | Holy Bind | 7 % | – | Shackle an undead 20 s; breaks on damage. |
| 20 | Mass Healing | 16 % | 20 s | Rain on a 3×3 area: SC×0.5/s to allies for 8 s. |
| 22 | Resurrection | 20 % | – | 10 s cast, out of combat. Revive a dead party member at 30 %. |
| 24 | Blessing | 7 % | – | Party +8 % DC/MC/SC, 10 min. |
| 26 | Ward | 10 % | 15 s | Absorb SC×5 for 30 s. |
| 30 | Summon Shinsu | 20 % | 60 s | Pet: damage-type hound. One pet at a time — choose. |
| 34 | Judgement | 12 % | 10 s | SC×2.5 holy, ×1.5 vs undead/demon. |
| 38 | Sanctuary | 15 % | 4 min | Party −50 % damage taken 6 s. |
| 40 | Guardian Spirit | 15 % | 3 min | Target survives the next killing blow at 20 % HP (10 s). |

Rotation feel: solo = Poison, Soul Fire, pet holds, Spirit Mend yourself. Group = Spirit Mend the tank, Healing as the filler, Quick Mend when it's scary, Ward before a big hit, Purify on poison, Mass Healing on stacked groups. The mana bar is the tension.

---

## 5. Progression

### 5.1 Levels and XP
- Cap **40** at launch (50 later with a second raid). Keep `xpNeed(L) = 60·L^2.15 + 40`.
- **Quests are the main XP source** (≈60 % of levelling), kills ≈35 %, exploration/discovery 5 % (first time entering a zone or sub-area: `player:xp` with a "Discovered: Marsh Landing" toast).
- Kill XP = `base(monLv) × conMultiplier` (grey = 0), split in groups (equal shares, +10 % per extra member).
- **Rested XP** (★ the come-back-tomorrow hook): while logged out (or logged out *in an inn/town*: ×4), you accrue rested XP at 5 % of a level per 8 h, up to 150 % of a level. Kill XP is doubled while rested. Shown as the blue part of the XP bar.

### 5.2 Milestones — the doors
| Lv | What opens |
|---|---|
| 1 | Class trainer, first ability, first quest hub (Ashvale farms). |
| 4 | Second ability; the "!" hub at the Mill outside town. |
| 6 | First green item can drop. Storage NPC opens. |
| 10 | **Defining ability.** First rare spawn possible. Guild membership. Con colours explained. |
| 12 | **Hollow Mine** becomes a 5-man dungeon (elite). The first "you'll need a group" moment; bots start LFM'ing it. |
| 16 | Mirewood hub. Guild founding (50 gold + a Warlord's Horn, which drops from the Goblin Warlord, a rare elite in Mirewood). Reputation with the Mirewood Wardens opens. |
| 20 | Hearthstone cooldown halves (60 → 30 min). First blue quest reward. Belt grows to 6 slots. |
| 24 | **Temple of Ash** dungeon (5-man). Mount quest chain begins (long, cozy, multi-zone). |
| 30 | Ashen Highlands zone. Daily quest board unlocks. Sanctum **attunement** chain begins (a story that walks you through every dungeon). World bosses roam. |
| 34 | **Varn Catacombs** dungeon (5-man, 34–40). Castle Varn siege events. |
| 40 | **Mount** (from the chain + 100 gold). **Abyssal Sanctum** raid (10-player: you + 9, requires attunement). Title "Hero of Ashvale". Endgame loop (section 9). |

**Gold scale** (so numbers above mean something): a player who does most quests has earned ~600 gold total by 40. Abilities cost 0.1–5 gold. A dungeon's repairs at 40 cost ~2 gold. The mount's 100 gold is the big purchase of a character's life. The first draft's prices are all ×100 too high and must be rescaled.

### 5.3 Quests
- **Hubs**: 3–5 quests per hub, mostly parallel, one chain. Hubs at: Ashvale town (1–6), the Mill (4–10), Miners' Camp (10–16), Mirewood Landing (14–22), Temple Gate (22–28), Highland Watch (26–34), Varn's Rest (34–40). ~70 quests to 40.
- **Types**: kill N, collect N drops, deliver (send you across the map to meet someone), explore, kill a named elite (**group quest**, marked), dungeon quest (turn in inside the dungeon — reason to run it), escort (rare, short), chain finale.
- **Markers**: yellow "!" available, grey "!" too high level, "?" ready to turn in. Quest log with objectives, a tracker on the HUD (max 5 tracked), map pins for objectives.
- **Voice**: Classic's — warm, plain, a little funny, never sarcastic, NPCs with a personal reason. Example, Farmer Hale at the Mill: *"Pests in the Fields — The hens won't lay, the fields are crawling and my brother's gone to town to complain instead of helping. Cull a dozen of the Field Rats and I'll make it worth your while. And if you see Tomas at the inn, tell him the fence still needs mending."* Rewards: XP, gold, a choice of two items (one per role), reputation.
- **Daily board** (lv 30+, Elder Rowan): three dailies a day, rotating from a pool (kill 20 of X, clear dungeon Y, kill any rare, gather 10 ore), each pays gold, reputation and 1 **Raider's Mark**. Marks buy: Bless Oil, an affix re-roll, and at 30 marks a blue-tier piece (bad-luck protection for people who never see a drop).

### 5.4 Reputation
Four factions, standings Neutral (0) → Friendly (3000) → Honored (9000) → Revered (21000) → Exalted (42000). Rep from zone quests, dungeon kills (+5 per elite), repeatable turn-ins (10 ore, 10 stalker hides…). Rewards at each standing sold by the faction quartermaster: recipes/consumables (Friendly), a blue (Honored), a trinket with an on-use (Revered), a cosmetic/mount skin/title (Exalted). Factions: **Ashvale Militia** (town + Mill), **Miners' Guild** (Mine), **Mirewood Wardens**, **Order of the Temple**.

### 5.5 Alts
One world, many characters. Each character has its own save; the *world* (bot roster, guild history, boss timers, AH) is shared. Rolling a Taoist alt after your Warrior hits 40 is a Classic ritual; bots should recognise the account ("is that GD2X's alt?").

---

## 6. Items and loot

### 6.1 Rarity (WoW colours; replaces the draft's gold/purple/orange)
| q | Name | Colour | Where from |
|---|---|---|---|
| 0 | Common | white | vendors, early quests |
| – | Junk | grey | vendor trash: "Cracked Boar Tusk", sells for gold. Cozy pocket-filler. |
| 1 | Uncommon | green | world drops (≈0.4 % from even-level mobs), quest rewards, rare spawns |
| 2 | Rare | blue | dungeon bosses (guaranteed one per boss), rare spawns, Honored rep, chain finales |
| 3 | Epic | purple | raid bosses (two per boss + set piece), Revered trinkets, world-boss |
| 4 | Mythic | orange | raid bosses ≈5 % per kill with pity at 20; each has an on-use power on **R**. Bind on pickup. Server-first announced. |

### 6.2 Item budget
Every item has an **item level** (`ilvl`, ≈ required level + rarity bonus: green +5, blue +10, purple +15, mythic +20). Stat budget = `ilvl × k(rarity)`, spent across base attributes and one or two secondary stats (crit, hit, spellpower, healpower, threat, resist). Random **affix** on greens and blues ("of the Bear": Stamina+Strength; "of the Owl": Intellect+Spirit; "of the Falcon": Agility+Stamina; "of Shadow Resist"…) so two drops of the same item can suit different classes. Purples and Mythics are fixed. Set bonuses (3/5 pieces) must **change how you play** (e.g. Abyssal 3-set: Revenge has no cooldown for 6 s after Taunt).

### 6.3 Binding and trade
Boss loot is **Bind on Pickup**. World drops and crafted items are **Bind on Equip** and tradeable with bots (and, later, listable on the auction house). Quest rewards are soulbound.

### 6.4 Slots
Keep Mir's eight: weapon, armour, helmet, necklace, bracelet ×2, ring ×2. Add **boots** and **belt** (small stats, more drop variety, visible on the character). Weapons: 1-hand + none (Warrior can use a *shield*? No — Mir warriors wield big swords; Iron Guard is the parry answer.)

### 6.5 Need / Greed
On a group kill that drops a green or better: `loot:roll:open` with the item and everyone eligible. Each player and bot votes **Need** (only if it's an upgrade for their class/role; bots check their own gear), **Greed**, or **Pass**, within 30 s (bots take 2–12 s, sometimes ask "anyone need?"). Highest need roll wins, else highest greed. Bots comment (winner: "yes!!", loser: "gz", healer who needed on a plate chest: everyone notices — see 8.6). Bots that win **visibly equip** the item.

### 6.6 Economy
Gold in: quest rewards, vendor trash, boss gold, selling to bots. Gold out: repairs (`0.02 gold × ilvl × %lost`), abilities, food, mount (100 g at 40, a lot), reagents, re-rolls. Bots buy at 0.6–1.2× vendor value depending on their need and mood; they never pay 2.75× (draft bug). Prices drift with a simple supply model (each item type has a "market heat" that rises when you sell it a lot). Scale: see the gold note under §5.2.

---

## 7. Dungeons, raids and bosses

### 7.1 Dungeons (5-player: you + 4)
Hollow Mine (12–16), Temple of Ash (22–28), Varn Catacombs (34–40, new). Each: 3–4 bosses, 8–12 trash packs each with a **priority** (caster, healer, or runner), one patrol, one optional boss, a dungeon quest inside, **daily lockout** per boss (resets 06:00 local). Entering requires a party of 2+ (the raid-finder's instant bots are gone; you ask in chat, or your guild, and people come — see 8). Bots who are in a dungeon **finish the run** before their schedule takes them offline.

### 7.2 Raids (10-player: you + 9)
Abyssal Sanctum (40, attuned): 4 bosses, **weekly lockout** (Wednesday 06:00 local). Composition target: 2 tanks, 3 healers, 5 DPS. Raid leader (a bot or you) calls pulls; bots follow the raid leader's target. Wipes are possible and should happen sometimes; a wipe means a graveyard run back together and someone saying "ok that was my fault". Raid loot is deliberately more generous than Classic's (about 12 epics a week across 10 people): with one human player, the point is that *you* see gear move, on you and on your friends.

### 7.3 Boss design rule
Every dungeon boss has **one signature mechanic**, telegraphed, that the *player* can answer whatever their class, and no enrage timer (pillar 6: pressure lives in the raid). Every raid boss has **two mechanics, a phase change at 50 %, and a 6-minute enrage** (damage ×3). Bots react correctly ~85 % of the time (so wipes are usually your fault, and occasionally theirs — that is what makes them people).

| Boss | Where | Frame | Signature |
|---|---|---|---|
| Old Tusk | Ashvale | rare elite (silver star) | Charge: 2 s telegraph line, sidestep it. |
| Foreman Gault | Mine | boss | Calls two miners every 30 s: kill adds or they buff him. |
| The Bone King | Mine (final) | boss | Bone Prison: a cage (HP `40·lv`) spawns on a random member; break it within 6 s or they take 40 %. |
| High Cultist Mora | Temple | boss | Casts Soul Drain (4 s) on a member: **interrupt her** (Pommel Strike, Silence Rune) **or Purify the target** — every class has an answer. Unanswered, she heals 20 %. |
| Ashen Colossus | Sanctum 1 | raid boss | Stomp: leave the 3-tile ring (telegraphed 2 s). Crush stacks on the tank: **tank swap** at 4. 50 %: two Ash Golems spawn, off-tank picks them up. |
| The Archivist | Sanctum 2 | raid boss | Silence zones drift across the room (healers move). Rune adds every 25 s must die in 10 s or he gains a stack of Lore (+10 % damage). 50 %: Open the Book — 8 s of raid-wide damage, Sanctuary/Ward moment. |
| Twin Wardens | Sanctum 3 | raid boss | Two bosses sharing a room: must die within 10 s of each other or both revive at 30 %. Every 30 s they **swap positions** (tanks re-pick). 50 %: Chains — two random members are tethered and must stand within 3 tiles. |
| Vaal the Undying | Sanctum (final) | raid boss | Adds every 18 s (DPS priority). 50 %: Void Nova (run out, 2 s telegraph). Soul Drain on a random member (interrupt or Purify). Enrage at 6 min. |

### 7.4 Loot from bosses
Dungeon boss: 1 blue (weighted 40 % to the party's classes), gold, potions, rep. Raid boss: 2 purples + 1 set token (turned in at the Sanctum quartermaster for your class piece) + a 5 % Mythic roll. Everything rolls need/greed (§6.5), bots included. **Pity** is per boss per character and counts kills *without a Mythic won by you*: at 20, the boss drops a Mythic and it is yours without a roll (bots: "gz, about time"). Trash in dungeons drops greens at 3×, BoE blues at 0.3 %.

---

## 8. The cast (bots)

The bots are the game. Everything in this section is about making them **people** rather than population.

### 8.1 The roster
A persistent cast of **about 48 characters at any time** (`src/sim/roster.js`), each with: `name, cls, role (tank|heal|dps), sex, look seed, lv (progresses), guild, home zone, joinDate, personality (5 dials: chatty, kind, competitive, lazy, dramatic), typing style (caps, typos, emotes, abbreviations), help trait (helpful | situational | selfish), schedule (weekday/weekend online windows in the player's local time), goals (a gear piece, a level, a rep), memory (of you), friendship (−100..100)`. New characters appear over the weeks (levels 1–5, "newbie" chat) and a few quit ("gtg, quitting for uni, love you all"), so the cast turns over slowly, but a character's identity never changes: same name = same person, forever. The roster is saved with the world. **Levelling pace:** bots gain roughly one level per 2 hours of *their* online time, capped so that at any moment about 40 % of the roster is under 20, 35 % is 20–39 and 25 % is 40 — there must always be people LFM'ing the Mine.

### 8.2 Presence
Population follows the real clock: quiet at 4 am, busy 7–11 pm, busiest Saturday. When you log in, the people online are the ones whose schedule says so. They stay in the world when you change zones (per-zone lists with a cheap off-screen sim: they quest, level, and travel between zones on roads with realistic travel time). Nobody teleports, ever, except by Hearthstone or a Gatekeeper, and you see them do it.

### 8.3 Behaviour by role
Tank bots use Taunt, hold packs, mark kill order in chat. Healer bots heal lowest-first, call "oom", drink between pulls, sometimes over-heal, sometimes tunnel the tank and let a DPS die. DPS bots wait ~3 s after the tank engages (the chatty ones don't and pull aggro). All bots use the same `ABILITIES` table as the player with real cooldowns and resources, wear real gear that changes their numbers, eat between fights, and die.

### 8.4 Grouping
Bots ask in chat ("LF2M Mine, have tank+heals"), answer your LFM within 10–90 s depending on who's online, whisper you first ("hey, need a healer? I'm 14"), travel to the dungeon (visible), and leave when their schedule ends ("sry gotta go, gf's home"). Guildmates invite you to things on a schedule ("Sanctum sat 2pm?"), remember if you came, and get slightly cooler if you flake three times. Groups persist across zones and dungeons.

### 8.5 Memory and relationships
Each bot keeps a short event memory about you (grouped 4 times, you gave them a ring, they ninja'd your belt, you helped them at level 8), which drives greetings ("wb!", "hey it's the guy who tanked mino for us"), willingness to help, and trade prices. Friendship rises with time spent grouped and gifts, falls with rudeness and leaving mid-run.

### 8.6 Drama, lightly
About once a week something happens: a ninja loot (bots gossip for days, the ninja's reputation falls, the guild kicks them), a guild merge, a server-first race between two guilds, someone's "farewell post", a newbie asking how to get to the Mine in general chat and three people answering. Keep it warm; nothing hateful, no slurs, no real-world topics.

### 8.7 Chat
Two layers:
1. **Ambient generator** driven by state: real names, real levels, real boss timers, real drops, actual quest objectives, per-line cooldowns so a line isn't reused for hours, four channels (General, LFG, Trade, Guild) plus Say, whispers and emotes (`/wave`, `/dance`, `/sit`). Typos and "*fix" follow-ups by persona.
2. **Direct conversation** with the player: optional language-model replies (persona + memory + world state in the prompt; API key entered by the player in Settings, stored locally). Without a key, a template dialogue tree with topic memory (4-turn depth) is the fallback. Either way, replies take a realistic time to "type" (40–90 wpm) and bots stop replying when they're in combat.

---

## 9. The give-back loop (why you log in tomorrow)

| Cadence | Hook |
|---|---|
| Every login | Rested XP; who's online; guild chat backlog; whispers you missed ("you were offline: Thorne: sanctum sat?") |
| Daily | Dungeon lockouts reset; three dailies; rare-spawn windows; a bot invites you somewhere |
| Weekly | Raid lockout; guild raid night; a world event (Castle Varn siege, a wandering world boss, a merchant caravan) |
| Ongoing | Ability ranks; reputations; the mount chain; collection log (every item seen/owned — "13/76"); titles; pity counters; the piece that hasn't dropped |
| Someday | Level 50 and the second raid; a second guild hall; alts |

**Offline catch-up:** on login the world simulates what happened since you left: bots levelled, boss timers moved, market prices drifted, guild messages were posted, someone hit 40. Summarised in the chat backlog. Never more than 30 lines.

---

## 10. What the presentation layer needs from the sim

The view (world art, characters, effects, camera, sound, every window and HUD element) is built by a different worker and reads state + subscribes to events (see `src/shared/events.js`). The sim must expose, at minimum:

- **Entity fields**: `kind, id, name, lv, cls, role, x, y, mt, mdur, dir, hp, maxhp, mp, maxmp, resource{type,val,max}, anim{state: idle|walk|attack|cast|channel|hit|die|sit|dead, t, total}, look (equipment appearance), buffs[] {id, t, total, stacks, debuff}, cast{ability, t, total}, gcd{t, total}, target, threatTop (mon), con (colour), elite, rare, boss, type, dead, ghost, sitting, afk, emote`.
- **Player extras**: `cooldowns{abilityId: {t,total}}, procs{abilityId: t}, rested, restedMax, combat (bool), party[], keys[], belt[], inv[], equip{}, durability per item, quests, reputations, pity, lockouts, gold, title`.
- **World**: `S.map {id, name, w, h, tiles, objects, spawns, graveyard, hub}`, `S.time {hour, minute, phase, dark, weather}`, `S.drops[] {item, q, x, y, owner, rollId}`, `S.online[]` (roster subset online now), `S.chat[]` with channels.
- **Every event in the catalogue**, with the payloads listed, emitted at the moment it happens (not batched).
- **Commands** (section 2 of ENGINEERING.md) for everything a click can do.

---

## 11. Build order (systems worker)

Each milestone leaves the game playable end-to-end and passes `tests/smoke_test.py`.

1. **M1 — Combat core.** Targeting, auto-attack, GCD, cast bars, resources, hit table, threat, taunt, con colours, monster speed rule, potion cooldown, death/ghost/graveyard, durability. Events emitted for everything. *Done when:* a Warrior can hold two mobs off a Taoist bot with Taunt/Sunder and the fight can be lost.
2. **M2 — Classes.** All three ability tables with ranks, trainers, stances, pets. Bots use the same tables by role. *Done when:* a 5-man Mine run with role bots works without teleporting or magic self-heals.
3. **M3 — Loot & items.** Rarity/ilvl/affixes, BoP/BoE, need/greed with bot votes and equip, boss loot tables with pity, junk, repair, vendor pricing, bot trade prices. *Done when:* a boss kill produces a roll window everybody votes in.
4. **M4 — Progression.** Quest hubs to 40 in the Classic voice, markers, tracker data, rested XP, discovery XP, reputations, dailies, lockouts, milestones, hearthstone/inn/gatekeepers, real-time day/night, offline catch-up.
5. **M5 — The cast.** Roster, schedules, presence per zone, memory, grouping/LFG/travel, guild life, drama, ambient chat generator, dialogue fallback + optional LLM hook, emotes, sitting/eating.
6. **M6 — Bosses & raid.** Signature mechanics, enrage, phases, raid leader logic, 10-player raid, weekly lockout, Mythics with pity, server-firsts, world events.
7. **M7 — Later:** auction house, cooking/fishing, level 50, second raid, second guild hall, castle siege map.

---

## 12. Numbers — the tuning appendix

Everything below is a starting value that makes the formulas in §3 produce sensible results at every level. Tune in code, then update here.

### 12.1 Targets
- Time-to-kill an even-level normal mob, solo, level-appropriate gear: Warrior 10–14 s, Wizard 8–10 s (3–4 casts), Taoist 12–15 s with pet.
- After three consecutive even mobs a solo player is at ~40 % HP (Warrior) or ~40 % MP (casters) and should eat/drink (Classic downtime, short).
- Two even mobs at once: winnable with cooldowns. Three: run. One elite: no, unless you are 3+ levels above it.
- Dungeon boss fight: 90–120 s. Raid boss: 3–5 min. A competent player wipes 1–2 times on a new raid boss.
- Time to 40 doing most quests: ~40 hours played; ~30 with rested.
- Drop rates: green world drop 0.4 %, BoE blue 0.03 %, dungeon boss blue 100 %, raid Mythic 5 % with pity at 20, rare spawns one per zone band on 1–3 h windows.

### 12.2 Player base attributes (level 1 value, + per level)
| Class | Str | Agi | Sta | Int | Spi |
|---|---|---|---|---|---|
| Warrior | 20 +1.6 | 14 +0.8 | 18 +1.4 | 8 +0.2 | 10 +0.3 |
| Wizard | 8 +0.2 | 10 +0.5 | 12 +0.9 | 22 +1.6 | 16 +1.0 |
| Taoist | 10 +0.4 | 11 +0.6 | 14 +1.0 | 18 +1.2 | 22 +1.6 |

`hpBase(lv)` = 20 + 12·lv (W), 20 + 8·lv (T), 20 + 6·lv (M). `mpBase(lv)` = 30 + 5·lv (M, T); Warriors have Rage instead.
Sanity: a level-40 Warrior in dungeon blues (≈ +90 Sta from gear) has ≈ 500 + 1,630 = **2,130 HP**; a level-40 Wizard ≈ **1,230 HP** and ≈ **2,400 MP** with ≈ 4 MP/s regen when not casting.

`avgWhiteHit(lv)` (used by rage) = 10 + 2.6·lv.

### 12.3 Monsters by level (normal)
- HP = 40 + 12·lv + 0.35·lv² (lv 1: 52 · lv 10: 195 · lv 20: 420 · lv 40: 1,080). Elite ×2.5, rare elite ×3, dungeon boss ×12, raid boss ×60.
- Melee damage per hit (2.0 s swing) = 3 + 1.2·lv + 0.04·lv² before the target's DR (lv 1: 4 · lv 20: 43 · lv 40: 115). Elite ×1.5, boss ×3, raid boss ×5. Casters do 1.3× as spell damage on a 2.5 s cast.
- AC = 30·lv, MAC = 5·lv (so an even-level attacker loses ~24 % physical / ~22 % magic at 40, ~15 % at 5).
- Aggro radius = 6 tiles, +1 per level the monster is above you, −1 per level below (min 2). Leash 25 tiles. Social radius 6.
- Kill XP base = 45 + 5·monLv, then the con multiplier (green ×0.7, yellow ×1, orange ×1.2, red ×1.3, grey ×0) and the group split. Elite ×2, boss ×5.

### 12.4 Items by item level
- Weapon average damage = 4 + 2·ilvl (range ±20 %). Speeds: dagger 1.6, sword 2.4, two-hander 3.0, staff 2.8, **wand 1.8** (casters auto-attack at range 8 with a wand for ~40 % of a sword's damage — the Classic wand, so casters never have to melee when out of mana).
- Armour AC per ilvl by slot, plate/chain (Warrior): armour 25, helmet 12, boots 7, belt 6, bracelet 4 each (58·ilvl total). Robes (casters) half that. Plus Agility×2. A level-40 Warrior in ilvl-50 blues ≈ **3,050 AC ≈ 45 % DR** vs level-40 attackers; a Wizard ≈ 28 %.
- MAC per ilvl (all slots together): robes 8, plate 3. Rings and necklaces carry stats and resist, no AC.
- **Stat budget** = ilvl × k, with k: white 0.5 · green 0.9 · blue 1.3 · purple 1.8 · mythic 2.2. One point buys: 1 primary attribute, or 1.5 spell/heal power, or 0.25 % crit, 0.2 % hit, 5 bonus AC, 2 MAC, 3 resist. Affixes spend the budget in a fixed pattern (of the Bear = 50 % Sta / 50 % Str, etc.).
- Required level = ilvl − rarity bonus (green 5, blue 10, purple 15, mythic 20). Repair cost = 0.02 gold × ilvl × fraction lost.

### 12.5 Consumables
| Tier | Level | HP potion | MP potion |
|---|---|---|---|
| Minor | 1 | 60 | 70 |
| Lesser | 10 | 150 | 180 |
| Greater | 20 | 350 | 420 |
| Superior | 30 | 700 | 840 |
| Major | 40 | 1,200 | 1,400 |
Potions are instant on a shared 120 s cooldown. Food/drink restore 30 % HP/MP over 20 s seated and give *Well Fed* (+8 Sta or +8 Spi, 30 min).

### 12.6 Time and movement
Player 4 tiles/s; mount +60 %. GCD 1.5 s. Cast pushback +0.5 s (max ×2). Hearthstone 60 min cooldown (30 min from level 20), 10 s cast, bound at any inn. Gatekeeper travel between visited hubs costs 0.1 gold × distance in hubs and takes real seconds (a fade and a short "flight"). Day = real time; dungeon reset 06:00 local; raid reset Wednesday 06:00 local. Roll window 30 s (default Pass). Bot reply latency 2–12 s in town, none in combat.

---

## 13. Glossary
**GCD** global cooldown · **con** the colour of a monster's level relative to yours · **BoP/BoE** bind on pickup/equip · **LFM/LFG** looking for more/group · **pity** guaranteed drop after N failures · **rested** bonus XP for time away · **proc** an ability that lights up because a condition was met · **wipe** everyone dies · **hub** a cluster of quest givers · **elite/rare/boss** monster frames silver dragon / silver star / gold.

## 14. Open questions for GD2X
1. Mount at 40: a horse, or something more Mir (a wolf, a tiger)? The view will build whichever.
2. Do you want PvP flags between bots at all (the draft's PK system)? Recommendation: keep the PK counter as *flavour only* (red names in town make for stories) and remove player-attacks-bot combat until much later.
3. Language-model bot chat: yes/no for launch? It's optional and behind a key either way.
