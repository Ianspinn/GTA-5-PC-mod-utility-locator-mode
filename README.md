# Utility Locate — FiveM job (GTA V)

A buried-utility locating job for FiveM. Pick up a ticket at the depot, drive
out to the site, hook up the transmitter, walk the receiver until the tone
peaks, and paint the line in APWA colours.

- **Buried utilities:** electric (red), gas (yellow), fiber/comms (orange),
  water (blue), sewer (green) — 10 ticket sites across Los Santos, Sandy
  Shores, Grapeseed, Paleto Bay and Banham Canyon
- **Transmitter + receiver gameplay:** the receiver only works near a live
  transmitter, signal strength falls off with distance, deeper lines read
  weaker, and the beep speeds up as you close in
- **Paint marks:** 4 marks per ticket, scored on accuracy — closer to the
  true line = bigger payout
- **No dependencies.** Standalone by default, optional ESX / QBCore payouts
- **Work truck:** a `utillitruck3` spawns at the yard on your first ticket

## Install

1. Drop the `utility-locate` folder into your server's `resources/` (e.g.
   `resources/[jobs]/utility-locate`).
2. Add `ensure utility-locate` to your `server.cfg`.
3. Restart the server. No database, no dependencies, no config required.

## How a locate works

1. Go to the **Utility Locate Depot** in Cypress Flats (yellow blip) and
   press **E** to pick up a ticket — or type `/locate` anywhere.
2. Drive to the site (GPS route + coloured blip).
3. At the access point (coloured marker), press **E** to hook up the
   transmitter. The transmitter box spawns on the ground.
4. Press **G** to power up the receiver. Walk the area — the HUD shows
   signal bars, the utility type, depth and your mark count, and the beep
   gets faster as you get closer to the line.
5. When the HUD reads **ON THE LINE**, press **E** to paint a mark. Marks
   must be at least 4m apart along the line.
6. After 4 marks the ticket closes automatically. Payout = $250 base +
   up to $250 accuracy bonus. Grab another ticket at the depot.

## Controls / commands

| Input | Action |
| --- | --- |
| E | Pick up ticket / hook up transmitter / paint mark |
| G | Toggle receiver |
| `/locate` | Start a ticket from anywhere |
| `/receiver` | Toggle receiver (same as G) |
| `/cancellocate` | Cancel the open ticket |

## Config (`config.lua`)

- `Config.Framework` — `'standalone'` (default), `'esx'` or `'qbcore'`.
  Standalone reports the payout in chat; ESX/QBCore pay it into the
  player's cash. Payouts are recomputed server-side, so clients can't
  fake them.
- `Config.MarksRequired`, `Config.MarkDistance`, `Config.MinMarkSpacing`,
  `Config.MaxSignalDistance`, `Config.TransmitterRange` — gameplay tuning.
- `Config.PayBase`, `Config.PayAccuracyBonus` — payout tuning.
- `Config.Sites` — add your own tickets. Each site needs a `label`, a
  `utility` key from `Config.Utilities`, a `depth` in metres, a `line`
  (two `vector2` points — the buried run), and an `access` point
  (`vector3`) where the transmitter hooks up. Lines are 2D (x, y) so they
  work on slopes; the script ground-snaps markers and paint automatically.

## Troubleshooting

- **No signal / receiver won't turn on:** the receiver only works after
  the transmitter is hooked up at the access point, on foot, and within
  60m of the transmitter.
- **Can't paint:** you must be within 2.5m of the true line (HUD reads
  ON THE LINE) and at least 4m from your last mark.
- **No payout:** standalone mode only reports the payout. Set
  `Config.Framework` to `'esx'` or `'qbcore'` on a server running that
  framework.
- **Resource won't start:** check the server console for errors and make
  sure the folder name is exactly `utility-locate` (the `ensure` line
  must match).

## GTA VI note

This was built for GTA V / FiveM because GTA VI is console-only (PS5 /
Xbox Series X|S) as of its November 19, 2026 launch, with no PC version
and no mod tools announced — there is nothing to install a VI mod into
yet. The design ports directly: same ticket/line data, same
transmitter-receiver-signal model. When a PC version and a script runtime
land, this becomes a ScriptHook/Cfx-style script with the same
`config.lua` site data.
