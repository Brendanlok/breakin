# Breakin — launch copy

Assets in this folder:

| File | What it is |
|---|---|
| `breakin-run.gif` | 23s loop, 320x553, 4.4 MB. A full run, empty arena to crusted, ending in a miss. This is the one that sells it — the inversion is invisible in a still. Recorded 4 Sep at the old x5; after the 10 Sep speed remap that is the same ball speed as today's default x3, so it still shows the game honestly. |
| `shot-1-open-arena.png` | Early run, arena still open. |
| `shot-2-closing-in.png` | Mid run, the walls are growing in. |
| `shot-3-sealed-in.png` | Late run, barely any room left. Strongest single image. |

Hosted once pushed: `https://brendanlok.github.io/breakin/press/breakin-run.gif`

## One-liner

> Breakout, except the ball never breaks anything. Every bounce turns that square
> permanently solid, so the arena closes in on you instead of opening up.

## Title options

- Breakin — Breakout, inverted: the ball builds the wall instead of breaking it
- I made a Breakout where nothing is ever destroyed — every bounce makes the arena smaller
- Breakin: one life, no blocks to clear, and the room fills up until you die

## r/WebGames

**Title:** Breakin — Breakout, inverted: every bounce turns that square permanently solid

Browser game, no sign-in, no ads, works on phones.

It's Breakout with the core rule flipped. The ball destroys nothing. Every time it
bounces — off a wall, off a block, off your paddle — the cell it just left turns
solid forever. Nothing is ever cleared. The arena crusts over and closes in, and
you get one life.

Your score is the number of blocks you generated times the ball-speed multiplier
you picked before starting, so a faster ball is worth more but gives you less time
to read the bounce. There's a shared leaderboard and a competitive mode where two
people play separate boards off one link and the highest total wins.

Fair warning on technique: hitting the ball dead centre is the worst thing you can
do. A centred hit sends it straight back the way it came, into the pocket it just
built, and that is how most runs actually end — not by missing. Meeting the ball
off centre is the whole game.

https://brendanlok.github.io/breakin/

## r/playmygame

**Title:** [HTML5] Breakin — Breakout where the ball builds the wall instead of breaking it

**Link:** https://brendanlok.github.io/breakin/

**Platform:** Browser (desktop + mobile, installable as a PWA)

**Free / paid:** Free, no ads, no sign-in

Breakout with one rule inverted: the ball never destroys anything. Every bounce
turns the cell it left permanently solid, so the play area shrinks as you survive.
One life, no levels to clear — the run ends when you miss.

Score = blocks generated x the ball-speed multiplier you chose on the menu, so
speed is a risk/reward dial rather than a difficulty setting. Shared leaderboard,
plus a competitive mode where two players take separate boards from one shared link.

Controls: A/D or arrow keys on desktop; on-screen buttons or device tilt on mobile.

Feedback I'd most like: does the inversion click within the first run, and is the
speed slider readable as a scoring choice rather than just "harder"? There's a
feedback box on the menu that goes straight to me.

## itch.io

Post here first — it is the natural home for a browser game, and the natural home
for the wider collection later.

**Title:** Breakin

**Tagline (short description, ~140 chars):**

> Breakout, inverted. The ball destroys nothing — every bounce turns that square
> solid, and the arena closes in until there is nowhere left to play.

**Description:**

Breakout with its core rule turned around. The ball never breaks anything. Every
time it bounces — off a wall, off a block, off your paddle — the cell it just left
turns solid forever.

Nothing is ever cleared. There are no levels to finish and no bricks to remove.
The arena crusts over as you rally, the space you have to work with shrinks, and
you get exactly one life. Most runs do not end because you missed. They end
because the ball walled itself into a pocket it could not get out of.

Your score is the number of blocks you generated times the ball-speed multiplier
you set before starting. A faster ball is worth more per block and kills you
sooner, so the slider is a wager, not a difficulty setting.

There is a shared leaderboard that needs no sign-in, and a competitive mode where
two people take separate arenas from one shared link and the higher score wins.

**How to play:**

- Desktop: A / D or the arrow keys
- Mobile: on-screen buttons, or tilt the device
- Hit the ball off centre. A centred hit sends it straight back into the pocket it
  just built, which is how most runs end.

**Metadata:**

- Kind of project: HTML5 / playable in browser
- Genre: Action / Arcade
- Tags: `arcade`, `breakout`, `singleplayer`, `leaderboard`, `mobile-friendly`, `no-install`, `minimalist`, `high-score`
- Price: Free
- Embed: point it at `https://brendanlok.github.io/breakin/`, 420x760, fullscreen button on, mobile friendly on

## Show HN

Frame it around the constraint, not the game — that is the part this audience
actually turns up for.

**Title:** Show HN: Breakout, inverted — the ball builds the wall instead of breaking it

**First comment:**

> I wanted to know what Breakout becomes if you invert the one rule it is built on.
> The ball destroys nothing; every bounce turns the cell it just left permanently
> solid. Nothing is ever cleared, so instead of opening the field up, you spend the
> whole run closing it down. One life.
>
> The interesting part is that it changes what kills you. In Breakout you die by
> missing. Here you mostly die because the ball sealed itself into a pocket it
> could not leave, which means centring your paddle under it — the correct instinct
> in Breakout — is actively wrong.
>
> The whole thing is one HTML file: vanilla JS and a canvas, no build step, no
> dependencies, no framework. Scores go to a Postgres table through PostgREST with a
> plausibility check as an insert trigger, and the competitive mode passes state
> through one shared row rather than a socket. That is the entire backend.
>
> No sign-in, no ads, works on a phone. Happy to talk about any of it.

**Don't:** post it as "I built a game" and lead with the leaderboard. Lead with the
inversion and the single-file constraint.

## Notes for posting

- r/playmygame requires a direct link plus platform and price stated up front — the
  template above already covers it.
- Lead with the GIF. In a still, Breakin looks like ordinary Breakout.
- Do not claim a player count or a rating the game doesn't have.
- PWA install is confirmed. Lok ran the real-device pass on 11 Sep — tilt, notch,
  audio and home-screen install all check out — so "installable as a PWA" in the
  r/playmygame template is a claim the game has actually earned. Leave it in.
- The leaderboard is empty until the first real player saves a score, so do not
  point at it as a reason to play on day one.
