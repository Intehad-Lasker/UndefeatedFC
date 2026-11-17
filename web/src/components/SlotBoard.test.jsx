import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, test, vi } from 'vitest'
import SlotBoard from './SlotBoard.jsx'

const skills = [
  { key: 'striking', label: 'Striking', description: 'Strikes landed per minute' },
  { key: 'power', label: 'Power', description: 'Knockout rate' },
]
const slots = [
  { key: 'striking', label: 'Striking', rating: 91, fighter: { id: 1, name: 'Rico Vance' } },
  { key: 'power', label: 'Power', rating: null, fighter: null },
]

test('filled slots show the fighter and the revealed rating', () => {
  render(<SlotBoard slots={slots} skills={skills} />)

  expect(screen.getByText('Rico Vance')).toBeInTheDocument()
  expect(screen.getByLabelText('Striking rating')).toHaveTextContent('91')
})

test('empty slots describe what they measure', () => {
  render(<SlotBoard slots={slots} skills={skills} />)

  expect(screen.getByText('Knockout rate')).toBeInTheDocument()
  expect(screen.queryByRole('button')).not.toBeInTheDocument()
})

test('with a fighter selected, empty slots become pick buttons', async () => {
  const onPick = vi.fn()
  render(<SlotBoard slots={slots} skills={skills} selectedFighter={{ id: 7, name: 'Ace Ardent' }} onPick={onPick} />)

  await userEvent.click(screen.getByRole('button', { name: 'Put Ace Ardent here' }))

  expect(onPick).toHaveBeenCalledWith('power')
})

test('no pick buttons while disabled', () => {
  render(<SlotBoard slots={slots} skills={skills} selectedFighter={{ id: 7, name: 'Ace Ardent' }} disabled />)

  expect(screen.queryByRole('button')).not.toBeInTheDocument()
})
