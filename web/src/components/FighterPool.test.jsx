import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, test, vi } from 'vitest'
import { fighter } from '../test/fixtures.js'
import FighterPool from './FighterPool.jsx'

const pool = [
  fighter(1, 'Cato Varga', { stats: { ...fighter(1).stats, sig_strikes_landed_per_min: 7.0 } }),
  fighter(2, 'Ace Ardent', { nickname: 'The Hammer', stats: { ...fighter(2).stats, sig_strikes_landed_per_min: 6.5 } }),
  fighter(3, 'Bea Garrow', { stats: { ...fighter(3).stats, sig_strikes_landed_per_min: 5.0 } }),
]

const names = () =>
  within(screen.getByRole('list', { name: 'Fighters in this pool' }))
    .getAllByRole('button')
    .map((button) => button.querySelector('strong').textContent)

test('lists fighters alphabetically by default', () => {
  render(<FighterPool pool={pool} onSelect={() => {}} />)

  expect(names()).toEqual(['Ace Ardent', 'Bea Garrow', 'Cato Varga'])
})

test('sorts by a stat, best first', async () => {
  render(<FighterPool pool={pool} onSelect={() => {}} />)

  await userEvent.selectOptions(screen.getByLabelText('Sort by'), 'Str/min')

  expect(names()).toEqual(['Cato Varga', 'Ace Ardent', 'Bea Garrow'])
})

test('filters by name or nickname', async () => {
  render(<FighterPool pool={pool} onSelect={() => {}} />)

  await userEvent.type(screen.getByLabelText('Filter'), 'hammer')

  expect(names()).toEqual(['Ace Ardent'])
})

test('says when nothing matches', async () => {
  render(<FighterPool pool={pool} onSelect={() => {}} />)

  await userEvent.type(screen.getByLabelText('Filter'), 'zzz')

  expect(screen.getByText('No fighters match “zzz”.')).toBeInTheDocument()
})

test('selecting a fighter reports it and marks it pressed', async () => {
  const onSelect = vi.fn()
  const { rerender } = render(<FighterPool pool={pool} onSelect={onSelect} />)

  await userEvent.click(screen.getByRole('button', { name: /Bea Garrow/ }))
  rerender(<FighterPool pool={pool} selectedId={3} onSelect={onSelect} />)

  expect(onSelect).toHaveBeenCalledWith(3)
  expect(screen.getByRole('button', { name: /Bea Garrow/ })).toHaveAttribute('aria-pressed', 'true')
})

test('cards show record and stats but never a rating', () => {
  render(<FighterPool pool={pool} onSelect={() => {}} />)

  const card = screen.getByRole('button', { name: /Ace Ardent/ })
  expect(card).toHaveTextContent('20-3-0')
  expect(card).toHaveTextContent('UFC 7-3 (4 KO, 1 SUB)')
  expect(card).toHaveTextContent('6.50')
  expect(card.textContent.toLowerCase()).not.toContain('rating')
})
