# Ashvale Online

A single-player MMORPG that runs in your web browser: the look of Legend of Mir 2, the heart of Classic World of Warcraft, and a cast of characters who live in the world whether or not you're there.

## Playing it

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
