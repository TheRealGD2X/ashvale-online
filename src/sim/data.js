'use strict';
/* ================= UTILS ================= */
const TW = 48, TH = 32;
const DX = [0, 1, 1, 1, 0, -1, -1, -1], DY = [-1, -1, 0, 1, 1, 1, 0, -1];
function mulberry(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
const R = Math.random;
const rnd = (a, b) => a + Math.floor(R() * (b - a + 1));
const pick = a => a[Math.floor(R() * a.length)];
const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
const lerp = (a, b, t) => a + (b - a) * t;
const cheb = (ax, ay, bx, by) => Math.max(Math.abs(ax - bx), Math.abs(ay - by));
const dist = (ax, ay, bx, by) => Math.hypot(ax - bx, ay - by);
function dirTo(ax, ay, bx, by) {
  const dx = Math.sign(bx - ax), dy = Math.sign(by - ay);
  for (let i = 0; i < 8; i++) if (DX[i] === dx && DY[i] === dy) return i;
  return 4;
}
function dirToPrecise(ax, ay, bx, by) {
  const a = Math.atan2(by - ay, bx - ax); // 0 = east
  let d = Math.round(a / (Math.PI / 4)); // -4..4
  return ((d + 2) % 8 + 8) % 8; // east(0)->2
}
function hash2(x, y, s) { let h = (Math.imul(x | 0, 374761393) + Math.imul(y | 0, 668265263) + Math.imul(s | 0, 982451653)) | 0; h = Math.imul(h ^ (h >>> 13), 1274126177); h = h ^ (h >>> 16); return (h >>> 0) / 4294967296; }
function vnoise(x, y, s) {
  const xi = Math.floor(x), yi = Math.floor(y), xf = x - xi, yf = y - yi;
  const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  const a = hash2(xi, yi, s), b = hash2(xi + 1, yi, s), c = hash2(xi, yi + 1, s), d = hash2(xi + 1, yi + 1, s);
  return lerp(lerp(a, b, u), lerp(c, d, u), v);
}
function fbm(x, y, s) { return vnoise(x, y, s) * .55 + vnoise(x * 2.1, y * 2.1, s + 7) * .3 + vnoise(x * 4.3, y * 4.3, s + 13) * .15; }
const fmt = n => Math.floor(n).toLocaleString('en-GB');
function shade(hex, amt) { // amt -1..1
  let c = hex.replace('#', ''); if (c.length === 3) c = c.split('').map(x => x + x).join('');
  let r = parseInt(c.slice(0, 2), 16), g = parseInt(c.slice(2, 4), 16), b = parseInt(c.slice(4, 6), 16);
  if (amt < 0) { r *= 1 + amt; g *= 1 + amt; b *= 1 + amt; } else { r += (255 - r) * amt; g += (255 - g) * amt; b += (255 - b) * amt; }
  return `rgb(${r | 0},${g | 0},${b | 0})`;
}
function esc(s) { return String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c])); }

/* ================= CLASSES ================= */
const CLASSES = {
  W: { name: 'Warrior', stat: 'dc', blurb: 'Heavy armour, huge health and brutal sword arts. Hard to kill, slow to fall.', color: '#c9533b' },
  M: { name: 'Wizard', stat: 'mc', blurb: 'Fragile, but commands fire, lightning and ice. Kills from a distance.', color: '#4d8fe0' },
  T: { name: 'Taoist', stat: 'sc', blurb: 'Heals, poisons and summons spirits. The most self-sufficient hunter.', color: '#58b36a' },
};
function baseStats(cls, L) {
  const s = { hp: 0, mp: 0, dc: [0, 0], mc: [0, 0], sc: [0, 0], ac: [0, 0], mac: [0, 0], acc: 5, agi: 10, luck: 0 };
  if (cls === 'W') {
    s.hp = Math.round(24 + 9 * L + 0.16 * L * L); s.mp = Math.round(8 + 2 * L);
    s.dc = [Math.floor(L / 3), Math.floor(L / 1.5) + 2]; s.ac = [Math.floor(L / 10), Math.floor(L / 6)]; s.mac = [0, Math.floor(L / 12)];
    s.acc = 7 + Math.floor(L / 6); s.agi = 12;
  } else if (cls === 'M') {
    s.hp = Math.round(16 + 4.2 * L + 0.06 * L * L); s.mp = Math.round(24 + 6 * L + 0.12 * L * L);
    s.dc = [0, 1 + Math.floor(L / 7)]; s.mc = [Math.floor(L / 3), Math.floor(L / 1.5) + 2]; s.mac = [0, Math.floor(L / 10)];
    s.acc = 5; s.agi = 13;
  } else {
    s.hp = Math.round(20 + 6.2 * L + 0.09 * L * L); s.mp = Math.round(18 + 4.5 * L + 0.08 * L * L);
    s.dc = [0, 1 + Math.floor(L / 5)]; s.sc = [Math.floor(L / 3), Math.floor(L / 1.6) + 2]; s.ac = [0, Math.floor(L / 9)]; s.mac = [Math.floor(L / 14), Math.floor(L / 8)];
    s.acc = 6; s.agi = 16;
  }
  return s;
}
const MAXLV = 40;
const xpNeed = L => Math.floor(60 * Math.pow(L, 2.15) + 40);

/* ================= SKILLS =================
 kind: passive | toggle | target | self | ground | summon | buff
*/
const SKILLS = {
  fencing: { cls: 'W', name: 'Fencing', lv: 1, kind: 'passive', mp: 0, desc: 'Sword discipline. +Accuracy each rank.', train: [40, 120, 300] },
  slaying: { cls: 'W', name: 'Slaying', lv: 5, kind: 'passive', mp: 0, desc: 'Every few swings strike a vital point for bonus damage and accuracy.', train: [80, 240, 600] },
  thrusting: { cls: 'W', name: 'Thrusting', lv: 11, kind: 'toggle', mp: 0, desc: 'Toggle. Your swings pierce a second enemy standing behind the first.', train: [120, 360, 900] },
  halfmoon: { cls: 'W', name: 'Half Moon', lv: 17, kind: 'toggle', mp: 3, desc: 'Toggle. Swings sweep a crescent through every adjacent enemy. Costs MP per swing.', train: [160, 480, 1200] },
  flaming: { cls: 'W', name: 'Flaming Sword', lv: 24, kind: 'self', mp: 12, cd: 10, desc: 'Ignites your blade. Your next swing deals massive fire damage.', train: [40, 120, 300] },
  dash: { cls: 'W', name: 'Shoulder Dash', lv: 29, kind: 'self', mp: 14, cd: 6, desc: 'Charge forward up to 3 tiles, knocking foes back and stunning them.', train: [40, 120, 300] },

  fireball: { cls: 'M', name: 'Fireball', lv: 1, kind: 'target', mp: 3, desc: 'Hurl a ball of flame at a single target.', train: [60, 180, 450], range: 9 },
  repulsion: { cls: 'M', name: 'Repulsion', lv: 8, kind: 'self', mp: 6, cd: 3, desc: 'A burst of force hurls adjacent enemies away.', train: [40, 120, 300] },
  thunder: { cls: 'M', name: 'Thunderbolt', lv: 12, kind: 'target', mp: 8, desc: 'Call lightning onto a target. Devastating against the undead.', train: [100, 300, 750], range: 9 },
  hellfire: { cls: 'M', name: 'Hell Fire', lv: 16, kind: 'target', mp: 11, desc: 'A torrent of flame burns everything in a line.', train: [100, 300, 750], range: 6 },
  shield: { cls: 'M', name: 'Magic Shield', lv: 21, kind: 'buff', mp: 22, cd: 2, desc: 'A shimmering barrier absorbs a share of all damage taken.', train: [30, 90, 220], dur: 60 },
  icestorm: { cls: 'M', name: 'Ice Storm', lv: 26, kind: 'ground', mp: 22, desc: 'Freezing storm strikes a 3x3 area and slows survivors.', train: [120, 360, 900], range: 9 },
  firewall: { cls: 'M', name: 'Fire Wall', lv: 31, kind: 'ground', mp: 26, cd: 2, desc: 'Leaves burning ground that scorches anything standing in it.', train: [80, 240, 600], range: 8 },

  healing: { cls: 'T', name: 'Healing', lv: 1, kind: 'heal', mp: 5, desc: 'Restore health to yourself, a party member or your summon.', train: [60, 180, 450], range: 8 },
  poison: { cls: 'T', name: 'Poisoning', lv: 5, kind: 'target', mp: 5, desc: 'Poison a target: damage over time and weakened armour.', train: [60, 180, 450], range: 8 },
  soulfire: { cls: 'T', name: 'Soul Fire Ball', lv: 9, kind: 'target', mp: 6, desc: 'A spirit flame that seeks its target.', train: [80, 240, 600], range: 9 },
  skeleton: { cls: 'T', name: 'Summon Skeleton', lv: 15, kind: 'summon', mp: 20, cd: 3, desc: 'Raise a skeleton warrior to fight at your side.', train: [30, 90, 220] },
  soulshield: { cls: 'T', name: 'Soul Shield', lv: 20, kind: 'buff', mp: 18, cd: 2, desc: 'Blesses you and your party with increased AC and MAC.', train: [30, 90, 220], dur: 90 },
  massheal: { cls: 'T', name: 'Mass Healing', lv: 25, kind: 'self', mp: 24, cd: 2, desc: 'Heals everyone friendly in a wide area.', train: [60, 180, 450] },
  hound: { cls: 'T', name: 'Summon Spirit Hound', lv: 30, kind: 'summon', mp: 32, cd: 3, desc: 'Summon a fire-breathing spirit hound. Replaces your skeleton.', train: [30, 90, 220] },
};

/* ================= ITEMS =================
 slot: weapon armour helmet necklace bracelet ring | cons | book | mat | quest
 q: rarity 0 common 1 rare(gold) 2 legendary(purple special)
*/
const ITEMS = {};
function I(id, o) { o.id = id; ITEMS[id] = o; }
// Weapons: look {k: sword|axe|dagger|staff|wand|blade|fan, c: colour}
I('wooden_sword', { name: 'Wooden Sword', slot: 'weapon', lv: 1, dc: [2, 5], price: 30, look: { k: 'wood', c: '#9a7448' } });
I('dagger', { name: 'Dagger', slot: 'weapon', lv: 1, dc: [3, 5], acc: 1, spd: 1, price: 60, look: { k: 'dagger', c: '#b9c2c9' } });
I('bronze_sword', { name: 'Bronze Sword', slot: 'weapon', lv: 5, dc: [3, 8], price: 260, look: { k: 'leaf', c: '#c8904e' } });
I('short_sword', { name: 'Short Sword', slot: 'weapon', lv: 9, dc: [4, 11], price: 720, look: { k: 'sword', c: '#c7ccd2' } });
I('bronze_axe', { name: 'Bronze Axe', slot: 'weapon', lv: 13, dc: [0, 16], price: 1500, look: { k: 'axe', c: '#c08a4a' } });
I('iron_sword', { name: 'Iron Sword', slot: 'weapon', cls: 'W', lv: 17, dc: [5, 19], price: 4200, look: { k: 'long', c: '#dfe6ec' } });
I('crescent', { name: 'Crescent Blade', slot: 'weapon', cls: 'W', lv: 22, dc: [5, 24], acc: 1, price: 9000, look: { k: 'curved', c: '#e7eef5' } });
I('war_axe', { name: 'Warlord Axe', slot: 'weapon', cls: 'W', lv: 27, dc: [6, 30], price: 16000, look: { k: 'greataxe', c: '#9aa3ab' } });
I('ravager', { name: 'Ravager', slot: 'weapon', cls: 'W', lv: 31, dc: [7, 35], acc: 2, price: 30000, q: 1, look: { k: 'serrated', c: '#6a2a2a', glow: '#ff3a2a' } });
I('dragon_slayer', { name: 'Dragon Slayer', slot: 'weapon', cls: 'W', lv: 35, dc: [8, 42], acc: 2, price: 80000, q: 1, look: { k: 'dragonblade', c: '#ffcf6a', glow: '#ff5a1a' } });
I('magic_wand', { name: 'Magic Wand', slot: 'weapon', cls: 'M', lv: 9, dc: [2, 5], mc: [1, 3], price: 900, look: { k: 'wand', c: '#7a5ad0' } });
I('bone_staff', { name: 'Bone Staff', slot: 'weapon', cls: 'M', lv: 16, dc: [3, 7], mc: [1, 5], price: 3800, look: { k: 'skullstaff', c: '#e8dfc8' } });
I('crystal_staff', { name: 'Crystal Staff', slot: 'weapon', cls: 'M', lv: 22, dc: [3, 9], mc: [2, 7], price: 9000, look: { k: 'crystalstaff', c: '#8fd6ff', glow: '#6ac8ff' } });
I('ember_staff', { name: 'Ember Staff', slot: 'weapon', cls: 'M', lv: 28, dc: [4, 11], mc: [2, 9], price: 18000, look: { k: 'emberstaff', c: '#ff8a4a', glow: '#ff6a2a' } });
I('dragon_staff', { name: 'Dragon Staff', slot: 'weapon', cls: 'M', lv: 35, dc: [5, 14], mc: [3, 13], price: 80000, q: 1, look: { k: 'dragonstaff', c: '#ffd257', glow: '#ffb020' } });
I('serpent_sword', { name: 'Serpent Sword', slot: 'weapon', cls: 'T', lv: 9, dc: [2, 7], sc: [1, 3], price: 900, look: { k: 'kris', c: '#7fcf83' } });
I('spirit_blade', { name: 'Spirit Blade', slot: 'weapon', cls: 'T', lv: 16, dc: [3, 9], sc: [1, 5], price: 3800, look: { k: 'jade', c: '#9fe8b3' } });
I('moon_sword', { name: 'Moon Sword', slot: 'weapon', cls: 'T', lv: 22, dc: [4, 11], sc: [2, 6], price: 9000, look: { k: 'moon', c: '#dfe8ff', glow: '#b8c8ff' } });
I('soul_reaver', { name: 'Soul Reaver', slot: 'weapon', cls: 'T', lv: 28, dc: [5, 13], sc: [2, 8], price: 18000, look: { k: 'reaver', c: '#5a8a6a', glow: '#50ff80' } });
I('dragon_fang', { name: 'Dragon Fang', slot: 'weapon', cls: 'T', lv: 35, dc: [5, 16], sc: [3, 12], price: 80000, q: 1, look: { k: 'fang', c: '#f4ecd8', glow: '#ffc030' } });
// Raid set (Abyssal Sanctum only)
I('abyss_blade', { name: 'Abyssal Greatsword', slot: 'weapon', cls: 'W', lv: 36, dc: [10, 48], acc: 3, price: 150000, q: 2, raid: 1, look: { k: 'abyssblade', c: '#3a2a5a', glow: '#b050ff' } });
I('abyss_staff', { name: 'Staff of the Lich Emperor', slot: 'weapon', cls: 'M', lv: 36, dc: [6, 16], mc: [4, 16], price: 150000, q: 2, raid: 1, look: { k: 'abyssstaff', c: '#2a1a3a', glow: '#b050ff' } });
I('abyss_fang', { name: 'Voidfang', slot: 'weapon', cls: 'T', lv: 36, dc: [6, 19], sc: [4, 15], price: 150000, q: 2, raid: 1, look: { k: 'abyssfang', c: '#4a3a6a', glow: '#b050ff' } });
// MYTHIC (q:3). Each carries an active power used with R. Only the raid boss drops them reliably.
I('worldbreaker', { name: 'Worldbreaker', slot: 'weapon', cls: 'W', lv: 38, dc: [12, 54], acc: 3, price: 500000, q: 3, look: { k: 'worldbreaker', c: '#4a3226', glow: '#ff6a1a' }, use: { id: 'meteor', cd: 60, name: 'Meteor', text: 'Call down a meteor on your target, crushing and burning everything around it.' } });
I('eternity', { name: 'Scepter of Eternity', slot: 'weapon', cls: 'M', lv: 38, dc: [6, 18], mc: [5, 19], price: 500000, q: 3, look: { k: 'eternity', c: '#e8f4ff', glow: '#6ae0ff' }, use: { id: 'timestop', cd: 75, name: 'Time Stop', text: 'Freeze every enemy within 7 tiles for 4 seconds. Frozen enemies take 30% more damage.' } });
I('spirit_tree', { name: 'Bough of the Spirit Tree', slot: 'weapon', cls: 'T', lv: 38, dc: [6, 20], sc: [5, 18], price: 500000, q: 3, look: { k: 'bough', c: '#6a4a2a', glow: '#7aff9a' }, use: { id: 'sanctuary', cd: 90, name: 'Sanctuary', text: 'Fully heal you, your group and your summon, and halve all damage you take for 6 seconds.' } });
I('dragon_heart', { name: 'Heart of the Dragon', slot: 'necklace', lv: 36, dc: [2, 6], mc: [2, 6], sc: [2, 6], hp: 80, price: 500000, q: 3, use: { id: 'dragonform', cd: 180, name: 'Dragon Form', text: 'Take the shape of a dragon for 15 seconds: +40% damage, and every attack breathes fire over the enemies in front of you.' } });
I('voidwalker', { name: 'Voidwalker Ring', slot: 'ring', lv: 36, dc: [1, 4], mc: [1, 4], sc: [1, 4], price: 400000, q: 3, use: { id: 'blink', cd: 18, name: 'Void Step', text: 'Blink to your cursor (up to 8 tiles), leaving a rift that tears at every enemy beside it.' } });
// Armour  look: {c: main, t: trim}
I('light_armour', { name: 'Light Armour', slot: 'armour', lv: 1, ac: [2, 2], price: 80, look: { c: '#7a5534', t: '#b08a5a', style: 'leather' } });
I('medium_armour', { name: 'Medium Armour', slot: 'armour', lv: 11, ac: [2, 4], mac: [0, 1], price: 1600, look: { c: '#8a9096', t: '#7a2a20', style: 'chain' } });
I('heavy_armour', { name: 'Heavy Armour', slot: 'armour', cls: 'W', lv: 21, ac: [4, 7], mac: [1, 2], price: 9500, look: { c: '#9aa2ac', t: '#d8b060', style: 'plate' } });
I('mage_robe', { name: 'Mage Robe', slot: 'armour', cls: 'M', lv: 21, ac: [3, 5], mac: [1, 3], mc: [0, 2], price: 9500, look: { c: '#3b3f8a', t: '#c9a6ff', style: 'robe' } });
I('soul_robe', { name: 'Soul Robe', slot: 'armour', cls: 'T', lv: 21, ac: [3, 6], mac: [1, 3], sc: [0, 2], price: 9500, look: { c: '#2f6a4a', t: '#e4d7a0', style: 'taorobe' } });
I('wargod', { name: 'War God Armour', slot: 'armour', cls: 'W', lv: 32, ac: [6, 10], mac: [2, 4], dc: [1, 3], price: 45000, q: 1, look: { c: '#8a2222', t: '#ffcc55', style: 'plate', cape: '#5a0a0a' } });
I('arcane_robe', { name: 'Arcane Robe', slot: 'armour', cls: 'M', lv: 32, ac: [4, 7], mac: [3, 5], mc: [1, 4], price: 45000, q: 1, look: { c: '#1d1b52', t: '#ffcc55', style: 'robe', cape: '#120f38', stars: 1 } });
I('spirit_robe', { name: 'Spirit Robe', slot: 'armour', cls: 'T', lv: 32, ac: [5, 8], mac: [3, 6], sc: [1, 4], price: 45000, q: 1, look: { c: '#ece6d4', t: '#3fae6a', style: 'taorobe', cape: '#cfe0d0', talismans: 1 } });
I('abyss_plate', { name: 'Abyssal Warplate', slot: 'armour', cls: 'W', lv: 36, ac: [7, 12], mac: [3, 5], dc: [2, 4], hp: 60, price: 120000, q: 2, raid: 1, look: { c: '#2a2438', t: '#b070ff', style: 'plate', cape: '#1a0a2a', stars: 1 } });
I('abyss_robe', { name: 'Robe of Endless Night', slot: 'armour', cls: 'M', lv: 36, ac: [5, 8], mac: [4, 7], mc: [2, 5], price: 120000, q: 2, raid: 1, look: { c: '#120a1e', t: '#b070ff', style: 'robe', cape: '#0a0612', stars: 1 } });
I('abyss_vest', { name: 'Vestment of the Void', slot: 'armour', cls: 'T', lv: 36, ac: [6, 9], mac: [4, 7], sc: [2, 5], price: 120000, q: 2, raid: 1, look: { c: '#2a2238', t: '#9aff9a', style: 'taorobe', cape: '#1a1426', talismans: 1, stars: 1 } });
// Helmets
I('leather_cap', { name: 'Leather Cap', slot: 'helmet', lv: 5, ac: [0, 1], price: 250, look: { c: '#7a5534', k: 'cap' } });
I('bronze_helm', { name: 'Bronze Helmet', slot: 'helmet', lv: 14, ac: [1, 2], price: 2200, look: { c: '#b87a3a', k: 'nasal' } });
I('magic_helm', { name: 'Magic Helmet', slot: 'helmet', lv: 20, ac: [1, 2], mac: [1, 2], price: 7000, look: { c: '#7a88b8', k: 'plume', p: '#c8302a' } });
I('skull_helm', { name: 'Skull Helm', slot: 'helmet', lv: 26, ac: [2, 4], mac: [1, 2], price: 15000, look: { c: '#e8e0cc', k: 'skull' } });
I('dragon_helm', { name: 'Dragon Helm', slot: 'helmet', lv: 33, ac: [3, 5], mac: [2, 3], hp: 30, price: 40000, q: 1, look: { c: '#d8a838', k: 'dragon' } });
I('abyss_crown', { name: 'Crown of the Abyss', slot: 'helmet', lv: 36, ac: [3, 6], mac: [3, 5], hp: 50, price: 100000, q: 2, raid: 1, look: { c: '#3a2a4a', k: 'abyss' } });
// Necklaces
I('bead_necklace', { name: 'Bead Necklace', slot: 'necklace', lv: 3, acc: 1, price: 300 });
I('gold_necklace', { name: 'Gold Necklace', slot: 'necklace', lv: 9, dc: [0, 1], mc: [0, 1], sc: [0, 1], price: 1300 });
I('fang_necklace', { name: 'Fang Necklace', slot: 'necklace', cls: 'W', lv: 14, dc: [0, 3], price: 3000 });
I('amber_necklace', { name: 'Amber Necklace', slot: 'necklace', cls: 'M', lv: 14, mc: [0, 3], price: 3000 });
I('jade_necklace', { name: 'Jade Necklace', slot: 'necklace', cls: 'T', lv: 14, sc: [0, 3], price: 3000 });
I('bone_necklace', { name: 'Bone Necklace', slot: 'necklace', cls: 'W', lv: 23, dc: [1, 5], price: 11000 });
I('crystal_necklace', { name: 'Crystal Necklace', slot: 'necklace', cls: 'M', lv: 23, mc: [1, 5], price: 11000 });
I('spirit_beads', { name: 'Spirit Beads', slot: 'necklace', cls: 'T', lv: 23, sc: [1, 5], price: 11000 });
I('luck_pendant', { name: 'Pendant of Fortune', slot: 'necklace', lv: 18, luck: 2, price: 25000, q: 1 });
I('abyss_amulet', { name: 'Heart of Vaal', slot: 'necklace', lv: 36, dc: [1, 4], mc: [1, 4], sc: [1, 4], luck: 1, price: 100000, q: 2, raid: 1 });
// Bracelets
I('iron_bracelet', { name: 'Iron Bracelet', slot: 'bracelet', lv: 5, ac: [0, 1], price: 220 });
I('silver_bracelet', { name: 'Silver Bracelet', slot: 'bracelet', lv: 12, ac: [0, 1], dc: [0, 1], price: 1600 });
I('blackiron_bracelet', { name: 'Black Iron Bracelet', slot: 'bracelet', cls: 'W', lv: 20, ac: [1, 2], dc: [0, 2], price: 6000 });
I('magic_bracelet', { name: 'Magic Bracelet', slot: 'bracelet', cls: 'M', lv: 20, mac: [0, 1], mc: [0, 2], price: 6000 });
I('spirit_bracelet', { name: 'Spirit Bracelet', slot: 'bracelet', cls: 'T', lv: 20, mac: [0, 1], sc: [0, 2], price: 6000 });
I('dragon_bracelet', { name: 'Dragon Bracelet', slot: 'bracelet', lv: 30, ac: [1, 2], mac: [1, 1], dc: [1, 2], mc: [1, 2], sc: [1, 2], price: 30000, q: 1 });
I('abyss_band', { name: 'Abyssal Band', slot: 'bracelet', lv: 36, ac: [2, 3], mac: [2, 3], dc: [1, 3], mc: [1, 3], sc: [1, 3], price: 90000, q: 2, raid: 1 });
// Rings
I('copper_ring', { name: 'Copper Ring', slot: 'ring', lv: 3, dc: [0, 1], price: 160 });
I('hex_ring', { name: 'Hexagon Ring', slot: 'ring', cls: 'W', lv: 10, dc: [0, 2], price: 1300 });
I('ruby_ring', { name: 'Ruby Ring', slot: 'ring', cls: 'M', lv: 10, mc: [0, 2], price: 1300 });
I('jade_ring', { name: 'Jade Ring', slot: 'ring', cls: 'T', lv: 10, sc: [0, 2], price: 1300 });
I('coral_ring', { name: 'Coral Ring', slot: 'ring', cls: 'W', lv: 20, dc: [1, 3], price: 7000 });
I('sapphire_ring', { name: 'Sapphire Ring', slot: 'ring', cls: 'M', lv: 20, mc: [1, 3], price: 7000 });
I('emerald_ring', { name: 'Emerald Ring', slot: 'ring', cls: 'T', lv: 20, sc: [1, 3], price: 7000 });
I('dragon_ring', { name: 'Dragon Ring', slot: 'ring', lv: 32, dc: [1, 4], mc: [1, 4], sc: [1, 4], price: 40000, q: 1 });
I('abyss_ring', { name: 'Signet of the Lich', slot: 'ring', lv: 36, dc: [2, 5], mc: [2, 5], sc: [2, 5], price: 90000, q: 2, raid: 1 });
// Special rings (legendary)
I('ring_paralysis', { name: 'Ring of Paralysis', slot: 'ring', lv: 20, special: 'paralyze', price: 60000, q: 2, sdesc: '10% chance on hit to paralyse the target for 2 seconds.' });
I('ring_revival', { name: 'Revival Ring', slot: 'ring', lv: 20, special: 'revive', price: 60000, q: 2, sdesc: 'Revives you where you fall. Recharges over 5 minutes.' });
I('ring_protection', { name: 'Protection Ring', slot: 'ring', lv: 20, special: 'protect', price: 60000, q: 2, sdesc: '30% of damage taken is drained from MP instead of HP.' });
I('ring_teleport', { name: 'Teleport Ring', slot: 'ring', lv: 12, special: 'teleport', price: 30000, q: 2, sdesc: 'Press T to teleport to a random spot on this map (10s recharge).' });
I('ring_healing', { name: 'Healing Ring', slot: 'ring', lv: 15, special: 'regen', price: 40000, q: 2, sdesc: 'Regenerates 2% of max HP every 2 seconds.' });
// Consumables
I('hp_s', { name: 'Health Potion (S)', slot: 'cons', heal: 40, price: 20, stack: 1, icon: 'hp' });
I('hp_m', { name: 'Health Potion (M)', slot: 'cons', heal: 100, price: 60, stack: 1, icon: 'hp' });
I('hp_l', { name: 'Health Potion (L)', slot: 'cons', heal: 240, price: 160, stack: 1, icon: 'hp' });
I('mp_s', { name: 'Mana Potion (S)', slot: 'cons', mana: 40, price: 22, stack: 1, icon: 'mp' });
I('mp_m', { name: 'Mana Potion (M)', slot: 'cons', mana: 100, price: 66, stack: 1, icon: 'mp' });
I('mp_l', { name: 'Mana Potion (L)', slot: 'cons', mana: 240, price: 170, stack: 1, icon: 'mp' });
I('sun_potion', { name: 'Sun Potion', slot: 'cons', heal: 180, mana: 180, instant: 1, price: 260, stack: 1, icon: 'sun' });
I('town_scroll', { name: 'Town Teleport Scroll', slot: 'cons', scroll: 'town', price: 120, stack: 1, icon: 'scroll' });
I('random_scroll', { name: 'Random Teleport Scroll', slot: 'cons', scroll: 'random', price: 60, stack: 1, icon: 'scroll2' });
I('bless_oil', { name: 'Bless Oil', slot: 'cons', oil: 1, price: 3500, stack: 1, icon: 'oil', desc: 'Pour on your equipped weapon to raise its Luck. The higher the Luck, the likelier it fails, and a failure can curse the blade.' });
I('black_ore', { name: 'Black Iron Ore', slot: 'mat', price: 400, icon: 'ore', desc: 'Dense ore from the Hollow Mine. The blacksmith uses it to refine weapons.' });
I('warlord_horn', { name: "Warlord's Horn", slot: 'quest', price: 5000, q: 1, icon: 'horn', desc: 'Proof of slaying the Goblin Warlord. Required to found a guild.' });
for (const [k, s] of Object.entries(SKILLS)) I('book_' + k, { name: 'Book: ' + s.name, slot: 'book', skill: k, cls: s.cls, lv: s.lv, price: Math.round(60 + s.lv * s.lv * 18), icon: 'book' });
/* Abyssal set bonuses change how each class plays, not just its numbers. */
function setBonusText(cls) {
  return [
    { n: 2, name: 'Void Rend', text: '+60 max HP. Your hits have an 8% chance to tear the void open for 150% bonus shadow damage.' },
    { n: 4, name: { W: 'Abyssal Onslaught', M: 'Void Conduit', T: 'Lich Pact' }[cls], text: { W: 'Half Moon and Thrusting cost no MP. Every 5th swing releases a shadow crescent that hits every enemy within 2 tiles.', M: 'Spells have a 15% chance to cost nothing and echo, casting themselves again a moment later.', T: 'Your summons rise as Abyssal servants: +50% health and damage, and they heal you for 3% of the damage they deal.' }[cls] },
    { n: 6, name: 'Heir of Vaal', text: '+2 Luck. When you drop below 30% HP you become the Lich for 10 seconds: you cannot die, you deal +50% damage and you drain 5% of it as HP (3 minute recharge).' },
  ];
}
const EQUIP_SLOTS = ['weapon', 'helmet', 'armour', 'necklace', 'braceletL', 'braceletR', 'ringL', 'ringR'];
const SLOTNAME = { weapon: 'Weapon', armour: 'Armour', helmet: 'Helmet', necklace: 'Necklace', bracelet: 'Bracelet', ring: 'Ring', cons: 'Consumable', book: 'Skill Book', mat: 'Material', quest: 'Quest Item' };

/* ================= MONSTERS =================
 body: hen deer biped quad worm flyer spider snake
*/
const MON = {};
function M(id, o) { o.id = id; MON[id] = o; }
// Ashvale fields
M('hen', { name: 'Hen', lv: 1, body: 'hen', col: '#f1eadc', passive: 1, spd: .8, hpm: .8, drops: [['hp_s', .06]] });
M('deer', { name: 'Deer', lv: 2, body: 'quad', col: '#9a6b3e', antlers: 1, passive: 1, spd: .55, hpm: 1, drops: [['hp_s', .06], ['copper_ring', .01]] });
M('scarecrow', { name: 'Scarecrow', lv: 4, body: 'biped', skin: '#d6b86a', cloth: '#6a5a8a', hat: 1, weapon: 'stick', spd: .8, drops: [['hp_s', .08], ['mp_s', .06], ['bead_necklace', .012], ['iron_bracelet', .012], ['leather_cap', .01]] });
M('wildcat', { name: 'Wildcat', lv: 6, body: 'biped', skin: '#c98a3e', cloth: '#5a3a2a', ears: 1, tail: 1, weapon: 'hook', spd: .6, aggro: 5, drops: [['hp_s', .08], ['bronze_sword', .012], ['copper_ring', .015], ['iron_bracelet', .015], ['leather_cap', .012]] });
M('wildcat_brute', { name: 'Wildcat Brute', lv: 9, body: 'biped', skin: '#8f5a2a', cloth: '#3a2a4a', ears: 1, tail: 1, weapon: 'rake', size: 1.12, spd: .65, aggro: 6, drops: [['hp_m', .06], ['short_sword', .01], ['gold_necklace', .006], ['magic_wand', .006], ['serpent_sword', .006], ['random_scroll', .03]] });
M('boar', { name: 'Wild Boar', lv: 8, body: 'quad', col: '#6a4a38', tusks: 1, spd: .55, aggro: 4, drops: [['hp_s', .1], ['iron_bracelet', .015]] });
M('old_tusk', { name: 'Old Tusk', lv: 14, body: 'quad', col: '#4a3226', tusks: 1, boss: 1, size: 1.9, spd: .6, aggro: 8, hpm: 9, dmgm: 1.4, respawn: 240, aura: '#ff9a3a',
  drops: [['hp_m', 1], ['hp_m', 1], ['short_sword', .35], ['medium_armour', .25], ['hex_ring', .15], ['ruby_ring', .15], ['jade_ring', .15], ['ring_teleport', .03], ['luck_pendant', .02]], gold: [300, 700] });
// Hollow Mine
M('cave_bat', { name: 'Cave Bat', lv: 8, body: 'flyer', col: '#4a3a52', wing: '#2a1f30', spd: .45, aggro: 7, drops: [['hp_s', .08]] });
M('maggot', { name: 'Cave Maggot', lv: 10, body: 'worm', col: '#c9b08a', spd: 1.0, aggro: 4, drops: [['hp_m', .06], ['black_ore', .03]] });
M('skeleton', { name: 'Skeleton', lv: 11, body: 'biped', bone: 1, skin: '#e6dfcc', cloth: null, weapon: 'sword', spd: .7, aggro: 7, undead: 1, drops: [['hp_m', .06], ['black_ore', .04], ['short_sword', .01], ['silver_bracelet', .008], ['leather_cap', .015]] });
M('axe_skeleton', { name: 'Axe Skeleton', lv: 13, body: 'biped', bone: 1, skin: '#d8d0b8', weapon: 'axe', ranged: { r: 5, proj: 'axe' }, spd: .75, aggro: 8, undead: 1, drops: [['hp_m', .06], ['black_ore', .04], ['bronze_axe', .01], ['hex_ring', .006], ['ruby_ring', .006], ['jade_ring', .006]] });
M('bone_fighter', { name: 'Bone Fighter', lv: 15, body: 'biped', bone: 1, skin: '#f2ecda', cloth: '#5a2020', helmet: 1, weapon: 'sword', shield: 1, size: 1.08, spd: .65, aggro: 7, undead: 1, drops: [['hp_m', .07], ['black_ore', .05], ['bronze_helm', .01], ['medium_armour', .01], ['fang_necklace', .006], ['amber_necklace', .006], ['jade_necklace', .006], ['bone_staff', .005], ['spirit_blade', .005]] });
M('zombie', { name: 'Zombie', lv: 14, body: 'biped', skin: '#7fa06a', cloth: '#4a4238', hunch: 1, spd: 1.0, aggro: 6, undead: 1, hpm: 1.3, drops: [['hp_m', .07], ['mp_m', .05], ['black_ore', .05], ['silver_bracelet', .008]] });
M('rot_zombie', { name: 'Rotting Zombie', lv: 17, body: 'biped', skin: '#5f8a4a', cloth: '#2e2a22', hunch: 1, spd: 1.0, aggro: 6, undead: 1, hpm: 1.4, poisonHit: 1, drops: [['hp_m', .07], ['black_ore', .06], ['iron_sword', .006], ['magic_helm', .004], ['sun_potion', .02]] });
M('bone_king', { name: 'Bone King', lv: 23, body: 'biped', bone: 1, skin: '#f7f1dc', cloth: '#3a1050', crown: 1, weapon: 'greatsword', boss: 1, size: 1.8, spd: .75, aggro: 10, undead: 1, hpm: 10, dmgm: 1.5, respawn: 360, aura: '#b060ff', summons: 'skeleton',
  drops: [['hp_l', 1], ['sun_potion', 1], ['black_ore', 1], ['iron_sword', .3], ['bone_staff', .3], ['spirit_blade', .3], ['bronze_helm', .3], ['magic_helm', .2], ['ring_paralysis', .04], ['ring_protection', .04], ['ring_healing', .05], ['luck_pendant', .04]], gold: [1200, 2500] });
// Mirewood
M('goblin', { name: 'Goblin', lv: 16, body: 'biped', skin: '#7c9a3a', cloth: '#6a4a2a', ears: 2, weapon: 'club', size: .85, spd: .6, aggro: 7, drops: [['hp_m', .07], ['mp_m', .05], ['silver_bracelet', .01], ['fang_necklace', .006], ['amber_necklace', .006], ['jade_necklace', .006]] });
M('goblin_fighter', { name: 'Goblin Fighter', lv: 18, body: 'biped', skin: '#6a8a2e', cloth: '#7a2a20', ears: 2, weapon: 'axe', shield: 1, size: .95, spd: .6, aggro: 7, drops: [['hp_m', .07], ['bronze_helm', .01], ['iron_sword', .006], ['bone_staff', .006], ['spirit_blade', .006]] });
M('goblin_shaman', { name: 'Goblin Shaman', lv: 20, body: 'biped', skin: '#5f8a5a', cloth: '#3a2a6a', ears: 2, weapon: 'staff', size: .9, ranged: { r: 6, proj: 'green' }, spd: .7, aggro: 8, mag: 1, drops: [['mp_m', .08], ['magic_bracelet', .008], ['spirit_bracelet', .008], ['crystal_staff', .004], ['moon_sword', .004]] });
M('spider', { name: 'Spitting Spider', lv: 19, body: 'spider', col: '#3a2e2a', mark: '#c93a2a', ranged: { r: 5, proj: 'spit' }, poisonHit: 1, spd: .55, aggro: 7, drops: [['hp_m', .08], ['sun_potion', .02], ['blackiron_bracelet', .006]] });
M('black_boar', { name: 'Black Boar', lv: 21, body: 'quad', col: '#2a2426', tusks: 1, size: 1.15, spd: .5, aggro: 6, hpm: 1.3, drops: [['hp_m', .1], ['blackiron_bracelet', .008], ['coral_ring', .004], ['sapphire_ring', .004], ['emerald_ring', .004]] });
M('snake', { name: 'Forest Viper', lv: 22, body: 'snake', col: '#4a7a3a', belly: '#c9c07a', poisonHit: 1, spd: .6, aggro: 6, drops: [['hp_m', .08], ['coral_ring', .004], ['sapphire_ring', .004], ['emerald_ring', .004]] });
M('goblin_brute', { name: 'Goblin Brute', lv: 24, body: 'biped', skin: '#56752a', cloth: '#5a1a14', ears: 2, weapon: 'club', size: 1.3, spd: .8, aggro: 7, hpm: 1.5, dmgm: 1.2, drops: [['hp_l', .06], ['crescent', .006], ['heavy_armour', .004], ['mage_robe', .004], ['soul_robe', .004], ['bone_necklace', .004], ['crystal_necklace', .004], ['spirit_beads', .004]] });
M('goblin_warlord', { name: 'Goblin Warlord', lv: 29, body: 'biped', skin: '#4a6a22', cloth: '#8a1a14', ears: 2, weapon: 'greataxe', warpaint: 1, crown: 1, boss: 1, size: 1.85, spd: .7, aggro: 10, hpm: 11, dmgm: 1.5, respawn: 420, aura: '#ff4a2a', summons: 'goblin_fighter',
  drops: [['warlord_horn', 1], ['hp_l', 1], ['sun_potion', 1], ['crescent', .3], ['crystal_staff', .3], ['moon_sword', .3], ['heavy_armour', .2], ['mage_robe', .2], ['soul_robe', .2], ['ring_paralysis', .05], ['ring_revival', .04], ['ring_protection', .05], ['dragon_bracelet', .05]], gold: [2500, 5000] });
// Temple of Khar
M('moth', { name: 'Temple Moth', lv: 25, body: 'flyer', col: '#b8a87a', wing: '#7a6a4a', moth: 1, spd: .45, aggro: 8, drops: [['mp_m', .08]] });
M('temple_archer', { name: 'Temple Archer', lv: 27, body: 'biped', stone: 1, skin: '#9a9486', cloth: '#6a6456', weapon: 'bow', ranged: { r: 7, proj: 'arrow' }, spd: .75, aggro: 9, drops: [['hp_l', .06], ['skull_helm', .006], ['war_axe', .004], ['ember_staff', .004], ['soul_reaver', .004]] });
M('stone_guardian', { name: 'Stone Guardian', lv: 30, body: 'biped', stone: 1, skin: '#8a8478', cloth: '#5a544a', weapon: 'greatsword', helmet: 1, size: 1.25, spd: .85, aggro: 7, hpm: 1.6, dmgm: 1.15, drops: [['hp_l', .07], ['skull_helm', .008], ['bone_necklace', .006], ['crystal_necklace', .006], ['spirit_beads', .006], ['war_axe', .005]] });
M('cultist', { name: 'Khar Cultist', lv: 32, body: 'biped', skin: '#b08a6a', cloth: '#4a0f1a', hood: 1, weapon: 'staff', ranged: { r: 6, proj: 'fire' }, mag: 1, spd: .65, aggro: 9, drops: [['mp_l', .07], ['sun_potion', .03], ['arcane_robe', .002], ['ember_staff', .005], ['soul_reaver', .005]] });
M('khar_elite', { name: 'Khar Elite', lv: 35, body: 'biped', stone: 1, skin: '#6a5a4a', cloth: '#3a1a1a', horns: 1, bull: 1, weapon: 'greataxe', size: 1.4, spd: .75, aggro: 8, hpm: 1.8, dmgm: 1.25, drops: [['hp_l', .08], ['wargod', .002], ['spirit_robe', .002], ['arcane_robe', .002], ['dragon_helm', .003], ['ravager', .003], ['dragon_ring', .003]] });
M('minotaur', { name: 'Khar Minotaur', lv: 40, body: 'biped', stone: 1, skin: '#5a4a3a', cloth: '#6a1010', horns: 1, bull: 1, crown: 1, weapon: 'greataxe', boss: 1, size: 2.2, spd: .75, aggro: 11, hpm: 13, dmgm: 1.6, respawn: 600, aura: '#ffb020', summons: 'stone_guardian', stomp: 1,
  drops: [['hp_l', 1], ['sun_potion', 1], ['sun_potion', 1], ['dragon_slayer', .1], ['dragon_staff', .1], ['dragon_fang', .1], ['wargod', .15], ['arcane_robe', .15], ['spirit_robe', .15], ['dragon_helm', .2], ['dragon_ring', .2], ['ring_revival', .08], ['ring_paralysis', .08], ['ravager', .15]], gold: [6000, 12000] });

// Abyssal Sanctum (raid)
M('abyss_knight', { name: 'Abyssal Knight', lv: 38, body: 'biped', bone: 1, skin: '#d8d0e8', cloth: '#2a1a3a', helmet: 1, weapon: 'greatsword', shield: 1, size: 1.2, spd: .7, aggro: 8, hpm: 2.2, dmgm: 1.3, undead: 1, drops: [['hp_l', .06], ['sun_potion', .03]] });
M('wraith', { name: 'Wraith', lv: 37, body: 'flyer', col: '#8a80b0', wing: '#3a3060', spd: .45, aggro: 9, hpm: 1.4, undead: 1, mag: 1, drops: [['mp_l', .06]] });
M('lich_acolyte', { name: 'Lich Acolyte', lv: 39, body: 'biped', skin: '#c8c0d8', cloth: '#2a0a3a', hood: 1, weapon: 'staff', ranged: { r: 6, proj: 'green' }, mag: 1, spd: .65, aggro: 9, hpm: 1.6, dmgm: 1.3, undead: 1, drops: [['mp_l', .06], ['sun_potion', .03]] });
M('colossus', { name: 'Bone Colossus', lv: 42, body: 'biped', bone: 1, skin: '#ece4d0', cloth: '#3a1a1a', crown: 1, weapon: 'greataxe', boss: 1, size: 2.1, spd: .8, aggro: 9, hpm: 16, dmgm: 1.6, respawn: 600, aura: '#c080ff', stomp: 1, summons: 'abyss_knight', undead: 1,
  loot: { n: [1, 1], pool: ['abyss_band', 'abyss_ring', 'abyss_amulet', 'dragon_ring', 'dragon_bracelet', 'dragon_helm'] }, drops: [['hp_l', 1], ['sun_potion', 1]], gold: [8000, 15000] });
M('vaal', { name: 'Vaal, the Lich Emperor', lv: 45, body: 'biped', bone: 1, skin: '#f4eefc', cloth: '#1a0a2a', crown: 1, hood: 0, weapon: 'abyssstaff', boss: 1, raid: 1, size: 2.5, spd: .8, aggro: 12, hpm: 34, dmgm: 1.9, respawn: 1200, aura: '#b050ff', stomp: 1, summons: 'abyss_knight', nova: 1, undead: 1, mag: 1,
  loot: { n: [2, 3], pool: ['abyss_blade', 'abyss_staff', 'abyss_fang', 'abyss_plate', 'abyss_robe', 'abyss_vest', 'abyss_crown', 'abyss_band', 'abyss_ring', 'abyss_amulet', 'dragon_slayer', 'dragon_staff', 'dragon_fang', 'ring_revival', 'ring_paralysis', 'worldbreaker', 'eternity', 'spirit_tree', 'dragon_heart', 'voidwalker'] }, drops: [['sun_potion', 1], ['sun_potion', 1]], gold: [20000, 40000] });

/* Loot philosophy: ordinary monsters drop consumables and the odd piece of common gear.
   Named (rare/legendary) gear only comes from dungeon bosses, and the best from the raid. */
for (const m of Object.values(MON)) {
  if (!m.boss) { m.drops = (m.drops || []).filter(([id]) => !ITEMS[id].q).map(([id, ch]) => [id, ITEMS[id].slot === 'cons' ? ch * .6 : ITEMS[id].slot === 'mat' ? ch : ch * .4]); continue; }
}
MON.old_tusk.loot = { n: [1, 1], pool: ['short_sword', 'medium_armour', 'hex_ring', 'ruby_ring', 'jade_ring', 'silver_bracelet', 'gold_necklace', 'magic_wand', 'serpent_sword', 'ring_teleport', 'luck_pendant'] };
MON.old_tusk.drops = [['hp_m', 1], ['hp_m', 1]];
MON.bone_king.loot = { n: [1, 2], pool: ['iron_sword', 'bone_staff', 'spirit_blade', 'bronze_helm', 'magic_helm', 'fang_necklace', 'amber_necklace', 'jade_necklace', 'blackiron_bracelet', 'magic_bracelet', 'spirit_bracelet', 'ring_paralysis', 'ring_protection', 'ring_healing', 'luck_pendant'] };
MON.bone_king.drops = [['hp_l', 1], ['sun_potion', 1], ['black_ore', 1], ['black_ore', .5]];
MON.goblin_warlord.loot = { n: [1, 2], pool: ['crescent', 'crystal_staff', 'moon_sword', 'heavy_armour', 'mage_robe', 'soul_robe', 'coral_ring', 'sapphire_ring', 'emerald_ring', 'bone_necklace', 'crystal_necklace', 'spirit_beads', 'ravager', 'dragon_bracelet', 'ring_revival'] };
MON.goblin_warlord.drops = [['warlord_horn', 1], ['hp_l', 1], ['sun_potion', 1]];
MON.minotaur.loot = { n: [2, 2], pool: ['dragon_heart', 'voidwalker', 'war_axe', 'ember_staff', 'soul_reaver', 'skull_helm', 'wargod', 'arcane_robe', 'spirit_robe', 'dragon_helm', 'dragon_ring', 'ravager', 'dragon_slayer', 'dragon_staff', 'dragon_fang', 'ring_revival'] };
MON.minotaur.drops = [['hp_l', 1], ['sun_potion', 1], ['sun_potion', 1]];

for (const [id, ch] of [['old_tusk', .15], ['bone_king', .3], ['goblin_warlord', .35], ['minotaur', .5], ['colossus', .5], ['vaal', 1]]) MON[id].drops.push(['bless_oil', ch]);
for (const m of Object.values(MON)) if (!m.boss && m.lv >= 15) m.drops.push(['bless_oil', .0015]);
function monStats(m) {
  const L = m.lv;
  const hp = Math.round((10 + 6 * L + 0.32 * L * L) * (m.hpm || 1) * (m.boss ? 1 : 1));
  const dm = m.dmgm || 1;
  return {
    hp, dmg: [Math.round((1 + L * 0.9) * dm), Math.round((3 + L * 1.55) * dm)],
    ac: [0, Math.round(L * 0.45)], mac: [0, Math.round(L * 0.35)], acc: 6 + Math.floor(L / 2), agi: 4 + Math.floor(L / 3),
    xp: Math.round((6 + 5.5 * Math.pow(L, 1.6)) * (m.boss ? 12 : 1) * (m.hpm ? Math.sqrt(m.hpm) : 1))
  };
}

/* ================= NPCs ================= */
const NPCS = [
  { id: 'elder', name: 'Elder Rowan', role: 'quest', look: { robe: '#5a4a7a', hair: '#e8e8e8', beard: 1 }, line: 'The fields grow wilder every season. Will you help Ashvale?' },
  { id: 'weapons', name: 'Borin', title: 'Weaponsmith', role: 'shop', stock: ['wooden_sword', 'dagger', 'bronze_sword', 'short_sword', 'bronze_axe', 'iron_sword', 'magic_wand', 'bone_staff', 'serpent_sword', 'spirit_blade'], look: { robe: '#6a3a1a', hair: '#3a2a1a', beard: 1, apron: 1 }, line: 'Steel for every hand. Look closely, stranger.' },
  { id: 'armour', name: 'Hilda', title: 'Armourer', role: 'shop', stock: ['light_armour', 'medium_armour', 'heavy_armour', 'mage_robe', 'soul_robe', 'leather_cap', 'bronze_helm', 'magic_helm'], look: { robe: '#4a5a6a', hair: '#c8742a', fem: 1 }, line: 'A good hauberk is worth ten swords.' },
  { id: 'jeweler', name: 'Mira', title: 'Jeweler', role: 'shop', stock: ['bead_necklace', 'gold_necklace', 'fang_necklace', 'amber_necklace', 'jade_necklace', 'iron_bracelet', 'silver_bracelet', 'copper_ring', 'hex_ring', 'ruby_ring', 'jade_ring'], look: { robe: '#7a2a5a', hair: '#1a1a2a', fem: 1 }, line: 'Rings, bracelets, charms. Some say the rare ones carry old magic.' },
  { id: 'potions', name: 'Wen', title: 'Apothecary', role: 'shop', stock: ['hp_s', 'hp_m', 'hp_l', 'mp_s', 'mp_m', 'mp_l', 'sun_potion', 'town_scroll', 'random_scroll', 'bless_oil'], look: { robe: '#2a6a4a', hair: '#6a6a6a' }, line: 'Potions fresh this morning. Never hunt without them.' },
  { id: 'books', name: 'Sage Orrin', title: 'Bookseller', role: 'books', look: { robe: '#2a2a5a', hair: '#bbbbbb', beard: 1, hat: 1 }, line: 'Every art begins with a book. Choose what your path allows.' },
  { id: 'smith', name: 'Grom', title: 'Blacksmith', role: 'smith', look: { robe: '#3a3a3a', hair: '#2a1a0a', beard: 1, apron: 1 }, line: 'Bring me Black Iron Ore and I will temper your weapon. No promises.' },
  { id: 'storage', name: 'Tam', title: 'Storage', role: 'storage', look: { robe: '#6a5a3a', hair: '#8a5a2a' }, line: 'Your things are safe with me. Mostly.' },
  { id: 'guild', name: 'Kael', title: 'Guild Master', role: 'guild', look: { robe: '#7a1a1a', hair: '#1a1a1a', armour: 1 }, line: 'Brotherhood wins wars. Castle Varn falls to the strongest guild.' },
  { id: 'gate', name: 'Lys', title: 'Gatekeeper', role: 'teleport', look: { robe: '#1a4a7a', hair: '#e8d8a8', fem: 1 }, line: 'For a fee I can open the way to places you have already walked.' },
];

/* ================= QUESTS ================= */
const QUESTS = [
  { name: 'Pests in the Fields', need: 'hen', n: 10, lv: 1, xp: 180, gold: 60, items: [['hp_s', 5]], text: 'Hens have overrun the east pastures. Thin them out.' },
  { name: 'Deer Culling', need: 'deer', n: 8, lv: 2, xp: 350, gold: 100, items: [['mp_s', 5], ['town_scroll', 1]], text: 'The deer strip our orchards bare. Eight should do.' },
  { name: 'Straw Men', need: 'scarecrow', n: 10, lv: 4, xp: 900, gold: 200, items: [['bead_necklace', 1]], text: 'Scarecrows walk by night now. Nobody knows why. Put them down.' },
  { name: 'Claws in the Grass', need: 'wildcat', n: 12, lv: 6, xp: 2200, gold: 400, items: [['hp_m', 5]], text: 'Wildcats ambush the farmers on the south road.' },
  { name: 'The Old Tusk', need: 'old_tusk', n: 1, lv: 10, xp: 6000, gold: 1200, items: [['sun_potion', 3], ['leather_cap', 1]], text: 'A monstrous boar roams the northeast meadow. Hunters call it Old Tusk.' },
  { name: 'Rattling Bones', need: 'skeleton', n: 15, lv: 11, xp: 9000, gold: 1500, items: [['hp_m', 10]], text: 'The Hollow Mine north-west of town is crawling with skeletons.' },
  { name: 'The Walking Dead', need: 'zombie', n: 12, lv: 14, xp: 15000, gold: 2000, items: [['mp_m', 10]], text: 'Zombies drag themselves through the deep tunnels. End them.' },
  { name: 'Crown of Bones', need: 'bone_king', n: 1, lv: 18, xp: 40000, gold: 5000, items: [['sun_potion', 5], ['black_ore', 3]], text: 'A king of bone rules the deepest chamber of the mine.' },
  { name: 'Goblin Menace', need: 'goblin', n: 20, lv: 16, xp: 30000, gold: 3500, items: [['hp_l', 5]], text: 'Goblins raid caravans on the Mirewood road, east of town.' },
  { name: 'Venom in the Trees', need: 'spider', n: 12, lv: 19, xp: 45000, gold: 4500, items: [['sun_potion', 5]], text: 'Spitting spiders nest deep in Mirewood.' },
  { name: 'The Warlord', need: 'goblin_warlord', n: 1, lv: 24, xp: 120000, gold: 12000, items: [['random_scroll', 5]], text: 'The Goblin Warlord gathers his horde in the eastern clearing. Break it.' },
  { name: 'Stone Eyes', need: 'temple_archer', n: 20, lv: 26, xp: 150000, gold: 12000, items: [['hp_l', 10]], text: 'The Sunken Temple lies beyond Mirewood. Its archers never sleep.' },
  { name: 'Unbreakable', need: 'stone_guardian', n: 15, lv: 29, xp: 220000, gold: 16000, items: [['mp_l', 10]], text: 'Stone Guardians bar the inner halls of the temple.' },
  { name: 'The Bull of Khar', need: 'minotaur', n: 1, lv: 34, xp: 600000, gold: 50000, items: [['sun_potion', 10]], text: 'At the heart of the temple waits the Khar Minotaur. Few return.' },
];

/* ================= BOTS / MMO FLAVOUR ================= */
const BOT_NAMES = ['Kaiser', 'xXShadowXx', 'Mystra', 'TaoMaster', 'Blaze99', 'IceQueen', 'Grimjaw', 'Lunara', 'DarkMage', 'Zephyr', 'Nyx', 'Ragnar', 'FoxyLady', 'Kenshin', 'Valkyr', 'Hexx', 'Moonfire', 'Tank4u', 'Spooky', 'Arcanis', 'Drako', 'Elara', 'KillSteal', 'NoobSlayer', 'Pumpkin', 'Rogue1', 'Sable', 'Thorne', 'Vex', 'Wolfie', 'Yuki', 'Bram', 'Cinder', 'Dusk', 'Ember', 'Frost', 'Gale', 'Hawke', 'Ivy', 'Jinx', 'Koda', 'LordAsh', 'Maverick', 'Nova', 'Onyx', 'Pax', 'Quill', 'Rune', 'Sly', 'Tempest', 'Umbra', 'Vale', 'Wren', 'Xander', 'Yarrow', 'Zed', 'OldSchool', 'MirVet', 'HealPlz', 'SoulFire', 'BigAxe', 'Pyro', 'Hunter88', 'AFKlol', 'GoldFarmer', 'CoolDude', 'Aria', 'Bolt', 'Crash', 'Doom', 'Echo'];
const GUILDS = [
  { name: 'Iron Oath', minLv: 1, notice: 'Casual guild. Be nice, share drops. Siege Saturdays.' },
  { name: 'Crimson Dawn', minLv: 12, notice: 'Active PvP guild. Lvl 12+. Castle Varn is ours.' },
  { name: 'Eternal', minLv: 20, notice: 'Boss hunters. Lvl 20+. Respect loot rules or get kicked.' },
];
const SHOUTS = [
  'Selling Bronze Axe cheap, pm me', 'LF group Hollow Mine', 'WTB Ring of Paralysis!!', 'anyone seen Old Tusk?', 'Crimson Dawn recruiting lvl 12+',
  'who killed the Bone King just now?? gg', 'selling hp pots near gate', 'WTS Crescent Blade 8k', 'need taoist for Temple run', 'Iron Oath recruiting all levels, friendly guild',
  'lol just died to a spider', 'WTB Black Iron Ore x5', 'goblin warlord up?', 'free buffs at town square', 'siege tonight, all Eternal members to Castle Varn',
  'is the temple worth it at lvl 25?', 'Buying Dragon Slayer, name your price', 'selling Magic Helmet', 'LFG Mirewood, lvl 19 wiz', 'PKer in Mirewood, watch out',
  'anyone want to group? lvl 14 war', 'gz on lvl 30 Ember!', 'mine is so laggy today', 'first Dragon Staff on server?? pics or it didnt happen', 'WTS Revival Ring, offers',
];
const SAYS = ['hi', 'yo', 'lol', 'nice', 'brb', 'gg', 'ty', 'need pots', 'anyone got a town scroll?', 'this spawn is mine', 'ks much?', 'lag', 'where is the mine?', 'nice gear', 'afk', 'wb', 'lol no', 'hunting here, sorry', 'omg', 'grats'];
const REPLIES = {
  hi: ['hey', 'hi!', 'yo', 'sup'], hello: ['hello', 'hey there'], lol: ['lol', 'haha'], gg: ['gg'], help: ['what do u need?', 'go to Elder Rowan in town'],
  group: ['sure, invite me', 'full atm sorry', 'what lvl?'], sell: ['how much?', 'not interested'], buy: ['what u selling?'], ty: ['np', 'no prob'], thanks: ['np'],
};
