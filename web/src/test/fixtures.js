// Small API payloads shaped like the real responses (see docs/api.md).
export const meta = {
  skills: [
    { key: 'striking', label: 'Striking' },
    { key: 'power', label: 'Power' },
  ],
  weight_classes: [
    { id: 1, name: 'Lightweight' },
    { id: 2, name: 'Welterweight' },
  ],
  eras: [
    { id: 10, name: 'Modern', label: 'Modern (2016-2020)' },
    { id: 11, name: 'Current', label: 'Current (2021-present)' },
  ],
  rules: { rounds: 2, fights: 15, min_choices: 8 },
}

export const fighter = (id, name, extra = {}) => ({
  id,
  name,
  nickname: null,
  record: '20-3-0',
  height_cm: 180,
  reach_cm: 185,
  stance: 'Orthodox',
  stats: {
    sig_strikes_landed_per_min: 4.5,
    sig_strike_accuracy: 0.5,
    sig_strikes_absorbed_per_min: 3.1,
    sig_strike_defense: 0.6,
    takedowns_per_15_min: 1.2,
    takedown_accuracy: 0.4,
    takedown_defense: 0.7,
    submission_attempts_per_15_min: 0.5,
  },
  ufc_record: { fights: 10, wins: 7, losses: 3, ko_wins: 4, submission_wins: 1 },
  ...extra,
})

const emptySlots = [
  { key: 'striking', label: 'Striking', round_number: null, rating: null, fighter: null },
  { key: 'power', label: 'Power', round_number: null, rating: null, fighter: null },
]

const openRound = {
  number: 1,
  weight_class: { id: 2, name: 'Welterweight' },
  era: { id: 10, name: 'Modern', label: 'Modern (2016-2020)' },
  picked: false,
  slot: null,
  rating: null,
  fighter: null,
  pool: [fighter(7, 'Ace Ardent', { stats: { ...fighter(7).stats, sig_strikes_landed_per_min: 6.1 } }), fighter(9, 'Bea Garrow')],
}

export const draftReady = { id: 'd1', status: 'in_progress', owned: true, slots: emptySlots, rounds: [], open_round: null, result: null }
export const draftPicking = { ...draftReady, rounds: [openRound], open_round: openRound }

export const draftCompleted = {
  ...draftReady,
  status: 'completed',
  slots: draftReady.slots.map((slot, index) => ({ ...slot, round_number: index + 1, rating: 90, fighter: fighter(index + 1, `Fighter ${index + 1}`) })),
  result: {
    overall: 90,
    wins: 15,
    losses: 0,
    record: '15-0',
    undefeated: true,
    fights: Array.from({ length: 15 }, (_, i) => ({ number: i + 1, opponent_rating: 55 + i * 2, win_probability: 0.9, won: true })),
  },
}
