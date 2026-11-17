# Data model

```mermaid
erDiagram
    WEIGHT_CLASSES ||--o{ BOUTS : "fought at"
    EVENTS ||--o{ BOUTS : "on the card of"
    BOUTS ||--|{ APPEARANCES : "has two"
    FIGHTERS ||--o{ APPEARANCES : "fights in"
    ERAS }o..o{ EVENTS : "date falls within"

    WEIGHT_CLASSES { string name UK
                     int limit_lbs
                     int position UK
                     bool spinnable }
    ERAS { string name UK
           date starts_on
           date ends_on "NULL = current era" }
    EVENTS { string ufcstats_id UK
             string name
             date held_on }
    BOUTS { string ufcstats_id UK
            string finish "ko_tko, submission, decision..."
            string finish_detail "raw UFCStats text"
            int ending_round }
    APPEARANCES { string outcome "win, loss, draw, no_contest"
                  int knockdowns
                  int sig_strikes_landed
                  int takedowns_landed
                  int submission_attempts }
    FIGHTERS { string ufcstats_id UK
               string name
               decimal sig_strikes_landed_per_min
               decimal sig_strike_accuracy
               decimal takedowns_per_15_min
               decimal takedown_defense }
    INGESTION_RUNS { string status "running, succeeded, failed"
                     datetime started_at
                     datetime finished_at }
```

## Why it is shaped this way

- **Eras link to events by date, not by foreign key.** An era is a date range, so
  "bouts in the Modern era" is `events.held_on BETWEEN starts_on AND ends_on`.
  A GiST exclusion constraint stops eras from overlapping, so every date maps to
  exactly one era.
- **Appearances instead of red/blue columns on bouts.** "Fighters who fought at
  Lightweight in 2016-2020" is one join through appearances, and per-fight stats
  have a natural home.
- **Weight classes and eras are tables, not enums.** Bouts get real foreign keys,
  and admins can change which divisions are spinnable without a deploy.
- **Rules are enforced twice.** Model validations give readable errors; CHECK,
  UNIQUE and exclusion constraints hold even if something writes around Rails
  (such as the Python scraper).
- **`ufcstats_id` is unique on every scraped table.** It is the key the scraper
  upserts on, so loading the same page twice updates rows instead of duplicating
  them.
