# JSON API (v1)

All endpoints live under `/api/v1` and speak JSON. The React app is the main
client, but anything that keeps cookies can use it.

## Conventions

- **Errors** always look like this, with the HTTP status matching the code:

  ```json
  { "error": { "code": "rule_violation", "message": "Pick a fighter before spinning again." } }
  ```

  | Status | Code | When |
  |---|---|---|
  | 400 | `bad_request` | A required parameter is missing |
  | 403 | `forbidden` | Changing a draft another browser started |
  | 403 | `invalid_csrf_token` | A write without a valid `X-CSRF-Token` header |
  | 401 | `unauthorized` | The endpoint needs a signed-in player |
  | 401 | `invalid_credentials` | Wrong email address or password |
  | 404 | `not_found` | Unknown draft or fighter |
  | 422 | `rule_violation` | The request breaks a game rule; the message is shown to the player |
  | 422 | `validation_failed` | Invalid sign-up; `fields` maps each field to its messages |
  | 429 | `rate_limited` | More than 20 new drafts per minute from one IP |

- **Player identity.** The first request sets a signed, HTTP-only cookie with
  an anonymous player id. Only that browser can spin or pick in the drafts it
  started; anyone with the link can view them.
- **CSRF.** Every response sets a readable `CSRF-TOKEN` cookie and an
  `X-CSRF-Token` header. Send the token back in `X-CSRF-Token` on `POST` and
  `DELETE` requests; browsers should read the cookie (see ADR 0010).
- **Accounts are optional.** Guests can play. Signed-in players' drafts follow
  them across browsers, and signing in claims the drafts that browser played
  as a guest.
- **Caching.** `GET` endpoints return an `ETag`. Repeat the request with
  `If-None-Match` to get `304 Not Modified` when nothing changed.
- **Ratings are hidden until picked.** Pools, search results and profiles show
  records and career stats but never ratings. A fighter's rating appears only
  on the draft slot they were picked into (see ADR 0008).

## Endpoints

### `GET /api/v1/meta`

Skill slots, spinnable weight classes, eras and the rules. Publicly cacheable.

```json
{
  "skills": [{ "key": "striking", "label": "Striking", "description": "Significant strikes landed per minute, rewarded for accuracy" }, "..."],
  "weight_classes": [{ "id": 1, "name": "Flyweight", "limit_lbs": 125 }, "..."],
  "eras": [{ "id": 1, "name": "Pioneer", "label": "Pioneer (1993-2000)", "starts_on": "1993-11-12", "ends_on": "2000-12-31" }, "..."],
  "rules": { "rounds": 6, "fights": 15, "min_choices": 8 }
}
```

### `POST /api/v1/drafts`

Starts a draft owned by this browser. Returns `201` and the draft (shape below).

### `GET /api/v1/drafts/:id`

The full draft. The same shape is returned by every draft endpoint.

```json
{
  "id": "e2958a19-d95f-4cee-b8b4-1887f3672dcc",
  "status": "in_progress",
  "owned": true,
  "slots": [
    { "key": "striking", "label": "Striking", "round_number": 1, "rating": 59, "fighter": { "id": 412, "name": "Dario Rask", "...": "..." } },
    { "key": "power", "label": "Power", "round_number": null, "rating": null, "fighter": null }
  ],
  "rounds": [
    { "number": 1, "weight_class": { "id": 4, "name": "Lightweight" }, "era": { "id": 2, "name": "Early Zuffa", "label": "Early Zuffa (2001-2005)" },
      "picked": true, "slot": "striking", "rating": 59, "fighter": { "...": "..." } }
  ],
  "open_round": {
    "number": 2, "weight_class": { "...": "..." }, "era": { "...": "..." }, "picked": false, "slot": null, "rating": null, "fighter": null,
    "pool": [
      { "id": 87, "name": "Ace Ardent", "nickname": null, "record": "14-3-0", "height_cm": 190, "reach_cm": 196, "stance": "Orthodox",
        "stats": { "sig_strikes_landed_per_min": 4.21, "sig_strike_accuracy": 0.49, "...": "..." },
        "ufc_record": { "fights": 9, "wins": 6, "losses": 3, "ko_wins": 4, "submission_wins": 0 } }
    ]
  },
  "result": null
}
```

When the sixth slot is filled, `status` becomes `completed` and `result` is set:

```json
"result": {
  "overall": 84, "wins": 13, "losses": 2, "record": "13-2", "undefeated": false,
  "fights": [{ "number": 1, "opponent_rating": 55, "win_probability": 0.993, "won": true }, "..."]
}
```

### `POST /api/v1/drafts/:draft_id/rounds`

Spins the next round. The server chooses the weight class and era (seeded per
draft, never repeating a pool) and returns `201` with the draft, now with an
`open_round` and its pool.

Errors: `422` if a round is already waiting for a pick or the draft is finished;
`403` if this browser did not start the draft.

### `POST /api/v1/drafts/:draft_id/picks`

```json
{ "pick": { "fighter_id": 87, "slot": "power" } }
```

Fills `slot` with the fighter and snapshots their rating. The pick that fills
the last slot also runs the title run and returns the result.

Errors: `400` if `fighter_id` or `slot` is missing; `422` if there is no open
round, the slot is filled or unknown, the fighter was already drafted, or the
fighter did not fight in this round's weight class and era.

### `GET /api/v1/fighters?q=`

Up to 20 fighters whose name or nickname matches `q`, tolerating typos
(`ferriera` finds `Ferreira`). Best matches first.

### `GET /api/v1/fighters/:id`

A fighter card plus `born_on`, the `pools` they can be drafted from, and their
ten most recent `recent_bouts` (event, date, weight class, outcome, finish,
opponent).

### Accounts

| Method and path | Body | Result |
|---|---|---|
| `GET /api/v1/session` | | `{ "user": { "id", "email_address", "display_name" } }` or `{ "user": null }` |
| `POST /api/v1/session` | `{ "email_address", "password" }` | `201` and the user; `401 invalid_credentials`; rate limited |
| `DELETE /api/v1/session` | | `204` |
| `POST /api/v1/users` | `{ "user": { "email_address", "display_name", "password" } }` | `201`, signed in; `422 validation_failed` |
| `POST /api/v1/passwords` | `{ "email_address" }` | `202` with the same message whether or not the address exists |
| `GET /api/v1/drafts` | | The signed-in player's 50 latest drafts with status, result and `picks_made`; `401` for guests |

Display names are 3-20 letters, numbers or underscores and unique regardless
of case. Passwords need at least 10 characters. The reset email links to the
server-rendered reset page, which shares the session cookie with the app.

### Daily challenge

| Method and path | Result |
|---|---|
| `GET /api/v1/daily_challenge` | `{ "day": "2026-11-17", "attempt": null }`, or this player's attempt (`id`, `status`, `overall`, `record`, `undefeated`) |
| `POST /api/v1/daily_challenge/attempt` | `201` and a new draft for today's challenge, or `200` and the existing attempt |

Every attempt at a day's challenge uses that day's seed, so everyone gets the
same six spins. Each browser and each account gets one attempt per day (UTC),
enforced by partial unique indexes. Challenge drafts include
`"daily_challenge": { "day": ... }` in the draft response.

### Leaderboards

| Method and path | Result |
|---|---|
| `GET /api/v1/leaderboards/daily` | Today's challenge standings; `?day=YYYY-MM-DD` for another day (`404` if none, `400` if malformed) |
| `GET /api/v1/leaderboards/all_time` | Each player's best finished run |

```json
{ "day": "2026-11-17", "entries": [
  { "rank": 1, "draft_id": "...", "display_name": "LivePlayer", "wins": 14, "losses": 1, "record": "14-1",
    "overall": 90, "undefeated": false, "completed_at": "..." }
] }
```

Only signed-in players' finished drafts appear. Ranking is wins, then overall,
with ties sharing a rank (`RANK()`); the earlier finish is listed first. Both
endpoints are publicly cacheable with ETags, and rankings are cached in Solid
Cache until the board changes.

### Live updates (Action Cable)

Connect to `/cable` and subscribe to `LeaderboardChannel` with
`{ "board": "daily" }` or `{ "board": "all_time" }`. When a board changes you
receive `{ "board": "daily", "day": "2026-11-17" }` (or `{ "board": "all_time" }`):
refetch that leaderboard. Guests may connect.

### Head-to-head matches

| Method and path | Result |
|---|---|
| `POST /api/v1/matches` | `201`, a new match with you in seat 1 (rate limited like drafts) |
| `GET /api/v1/matches/:id` | The match: `status` (`waiting`, `drafting`, `completed`), `your_seat`, `current_seat`, `round`, `players`, the round's `pool` (fighters without ratings), both `boards` (ratings revealed), and `result` |
| `POST /api/v1/matches/:id/join` | Takes seat 2 and starts the draft; returns your existing seat if you're already in; `422` if full |
| `POST /api/v1/matches/:id/picks` | `{ "pick": { "fighter_id", "slot" } }` on your turn; `403` if you're not a player; `422` out of turn, slot filled, fighter taken or not in the pool |

The match id is the invite link. The six round pools are fixed when the match
is created; players alternate picks in snake order (1, 2, 2, 1, ...). After the
twelfth pick the builds fight up to five rounds (first to three wins).

Subscribe to `MatchChannel` with `{ "id": "<match id>" }` to be told when a
player joins or picks, then refetch the match.

Player ids are only created by actions that create something (a draft, a
challenge attempt, a match, a join). Reads never mint one, so a new browser's
parallel first requests can't swap its identity.

## Example session

```bash
B=http://localhost:3000/api/v1
TOKEN=$(curl -s -c jar -b jar -D - -o /dev/null $B/meta | awk -F': ' 'tolower($1)=="x-csrf-token"{print $2}' | tr -d '\r')
DRAFT=$(curl -s -c jar -b jar -X POST -H "X-CSRF-Token: $TOKEN" $B/drafts | jq -r .id)
curl -s -c jar -b jar -X POST -H "X-CSRF-Token: $TOKEN" $B/drafts/$DRAFT/rounds | jq '.open_round.pool[0]'
curl -s -c jar -b jar -X POST -H "X-CSRF-Token: $TOKEN" -H "Content-Type: application/json" \
  -d '{"pick":{"fighter_id":87,"slot":"power"}}' $B/drafts/$DRAFT/picks | jq '.slots'
```
