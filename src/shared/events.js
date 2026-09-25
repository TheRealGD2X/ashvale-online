/* =====================================================================
   src/shared/events.js — the seam between the simulation and the view.
   Owned jointly. Change it only with a note in docs/ENGINEERING.md.

   The rule of the house:
     * The SIM (src/sim/*) never touches the DOM, the canvas, or audio.
       When something happens that the player should see or hear, it
       calls EV.emit('name', payload) and moves on.
     * The VIEW (src/view/*) subscribes with EV.on('name', fn) and turns
       events into sprites, particles, sounds, combat text and UI updates.
     * The view drives the sim only through the command API (G.*), never
       by poking S directly. Reading S is fine.

   Event catalogue (payload fields in braces). Add new ones here first.
   ---------------------------------------------------------------------
   world
     zone:enter        { id, name, x, y }               map loaded, player placed
     time:tick         { phase, dark }                   0..1 day phase, darkness 0..1
   combat
     combat:hit        { src, tgt, dmg, crit, school, ability, absorbed, miss, dodge, parry, block }
     combat:heal       { src, tgt, amount, crit, ability }
     combat:miss       { src, tgt, kind }                kind: miss|dodge|parry|block|resist
     combat:cast:start { src, ability, castTime }
     combat:cast:end   { src, ability, ok }              ok=false when interrupted
     combat:buff       { tgt, buff, apply:true|false }
     combat:threat     { mon, top, prev }                aggro changed hands
     combat:enter      { }                               player entered combat
     combat:leave      { }
     combat:kill       { src, tgt, boss }
     player:death      { killer }
     player:revive     { }
   progression
     player:levelup    { lv }
     player:xp         { amount, rested }
     player:rested     { amount }                        rested XP gained while away
     ability:ready     { ability }                       cooldown finished / proc lit up
     ability:learn     { ability }
     quest:accept      { id } | quest:progress { id, n, of } | quest:complete { id } | quest:turnin { id }
     rep:gain          { faction, amount, standing }
   items
     loot:drop         { drop, q, boss }                 q: 0 common 1 rare 2 legendary 3 mythic
     loot:pickup       { item, q }
     loot:roll:open    { drop, rollers }                 need/greed window
     loot:roll:vote    { drop, who, vote }               vote: need|greed|pass
     loot:roll:won     { drop, who }
     item:equip        { slot, item }
     item:use          { item }
     gold:change       { delta, total }
   social
     chat              { ch, from, text, to }            ch: say|shout|guild|group|whisper|sys|loot|xp
     party:change      { members, leader }
     party:invite      { from }
     trade:open        { with } | trade:update { offer } | trade:done { ok }
     bot:emote         { who, emote }                    wave|dance|sit|laugh...
   ui hints (sim asks the view to show something, view decides how)
     ui:toast          { text, kind }
     ui:alert          { text }                          red centre-screen text
     ui:dirty          { what }                          inv|char|skills|quest|party|belt|target
   ===================================================================== */
const EV = (() => {
  const L = new Map();
  const on = (name, fn) => { if (!L.has(name)) L.set(name, new Set()); L.get(name).add(fn); return () => off(name, fn); };
  const off = (name, fn) => { const s = L.get(name); if (s) s.delete(fn); };
  const once = (name, fn) => { const un = on(name, p => { un(); fn(p); }); return un; };
  const emit = (name, payload) => {
    const s = L.get(name); if (!s) return;
    for (const fn of s) { try { fn(payload || {}); } catch (e) { console.error('[EV ' + name + ']', e); } }
  };
  return { on, off, once, emit, _l: L };
})();
const CONTRACT_VERSION = 1;
