# Ashvale Online

A single-player MMORPG that runs in your web browser: the look of Legend of Mir 2, the heart of Classic World of Warcraft, and a cast of characters who live in the world whether or not you're there.

## The 3D game: start here

Double-click **`Play Ashvale.bat`** in this folder. The first time, it sets itself up from the art packs in your Downloads folder, which takes a few minutes. After that it opens straight into the game.

**Controls**
- **Moving and fighting:**
  - Left-click the ground to walk there.
  - Left-click a monster to attack it.
  - Right-drag to turn the camera, and scroll to zoom.
  - Press **1–5** to use the abilities on your bar.
- **Your windows:**
  - **B** bags, **C** character, **L** quest log, **N** talents, **M** the big map.
  - **P** your spellbook. Drag abilities onto the bar.
- **Other keys:**
  - **Z** gets on or off your stag (from level 40).
  - **R** uses the power of a Mythic weapon, if you're lucky enough to have one.
  - **Enter** opens chat.
- **Chat commands:** `/w Name` whisper, `/p` party, `/invite Name`, `/who`, `/lfm` call for a raid, `/raidinfo` see which raid bosses you've beaten this week.
- **People:** click them. A yellow **!** means they have work for you, a yellow **?** means you've finished it.

**The road, level 1 to 60**

| Levels | Zone | Town | Dungeon |
|---|---|---|---|
| 1–10 | Ashvale Province | Ashvale | — |
| 10–16 | Hollow Cliffs | Miners' Camp | The Hollow Mine |
| 14–22 | Mirewood | Mirewood Landing | The Warrens |
| 20–28 | Ash Slopes | Temple Gate | Temple of Ash |
| 26–34 | Ashen Highlands | Highland Watch | Sunken Crypts |
| 34–40 | Varn Plateau | Varn's Rest | Varn Catacombs |
| 40–46 | Saltmere Coast | Gullhaven | The Drowned Hold |
| 46–52 | Emberreach | Forgehold | The Molten Deep |
| 52–57 | The Pale Reach | Wintermere | Frostspire Halls |
| 57–60 | Vaal's Scar | The Last Watch | **Raid: the Abyssal Sanctum** |

Each zone ends with a letter or errand that sends you to the next. Dungeons need a group of two or more. Invite one of the other players from their portrait, or with `/invite Name`. The raid needs the Sanctum Key, which comes at the end of the Scar's story. Talk to Keeper Orlane at the Gate (or type `/lfm`) and nine people will come to raid with you.

## Playing it (the older web version)

**On the web:** open https://therealgd2x.github.io/ashvale-online/ in any browser, on any computer. This is the published copy; it updates a minute or two after new work is pushed up.

**On this PC:** double-click `index.html` in this folder. No install.

Your character saves itself in the browser every few seconds and when you close the tab. The web copy and the local copy each keep their own save.

## What's in the folder

| | |
|---|---|
| `index.html` | The game. |
| `src/sim/` | The rules of the game: classes, monsters, items, combat, quests, the bots. *(systems worker)* |
| `src/view/` | Everything you see and hear: art, animation, effects, sound, the whole interface. *(presentation worker)* |
| `src/shared/` | The small piece both halves talk through. |
| `docs/DESIGN.md` | The design bible: what the game is and how everything is meant to work. Worth reading if you're curious; it's written in plain language. |
| `docs/ENGINEERING.md` | The technical handover for the systems worker. |
| `docs/START-HERE-WORKER-B.md` | The note to paste to a new systems worker. |
| `CHANGELOG.md` | What each worker did, newest first, with a plain-English note for you at the end of each session. |
| `tests/` | An automatic check that the game still runs. |
| `screenshots/` | Pictures of the first draft, for reference. |

## GitHub

The project lives at https://github.com/TheRealGD2X/ashvale-online (public) and the web address above is served from it. GitHub Desktop is installed and signed in on this PC and points at this folder.

**Sending up new work.** When a worker says a build is ready: open GitHub Desktop, type a couple of words in the *Summary* box at the bottom-left (for example `new build`), click **Commit to main**, then **Push origin** at the top. A minute or two later, refresh the game in your browser. A worker that has been given control of GitHub Desktop can do these clicks for you.

## Working with two workers

- Give the systems worker this folder and paste: *"Read docs/START-HERE-WORKER-B.md and follow it."*
- Run **one worker at a time** in this folder. Let one finish and commit before you start the other, or their changes can overwrite each other.
- Each worker leaves you a plain-English note at the top of `CHANGELOG.md`: what changed, what to try, what's next.

## Backing up your character

A *Save to file* / *Load from file* button is coming to the menu. Until then, your save lives in the browser you play in; clearing the browser's site data would remove it.
