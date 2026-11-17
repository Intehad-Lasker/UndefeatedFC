import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, expect, test, vi } from 'vitest'
import ResultCard from './ResultCard.jsx'

const fights = (wins) =>
  Array.from({ length: 15 }, (_, i) => ({ number: i + 1, opponent_rating: 55 + i * 2, win_probability: 0.8, won: i < wins }))

const result = (wins) => ({ overall: 88, wins, losses: 15 - wins, record: `${wins}-${15 - wins}`, undefeated: wins === 15, fights: fights(wins) })

afterEach(() => vi.unstubAllGlobals())

test('shows the record, overall and every fight', () => {
  render(<ResultCard result={result(13)} shareUrl="http://x/drafts/1" />)

  expect(screen.getByText('13-2')).toBeInTheDocument()
  expect(screen.getByText('88')).toBeInTheDocument()
  const list = screen.getByRole('list', { name: 'Fights' })
  expect(within(list).getAllByRole('listitem')).toHaveLength(15)
  expect(within(list).getAllByText('L')).toHaveLength(2)
  expect(screen.queryByText('Undefeated')).not.toBeInTheDocument()
})

test('celebrates a 15-0 run', () => {
  render(<ResultCard result={result(15)} shareUrl="http://x/drafts/1" />)

  expect(screen.getByText('Undefeated')).toBeInTheDocument()
})

test('copies the share link', async () => {
  const writeText = vi.fn().mockResolvedValue(undefined)
  vi.stubGlobal('navigator', { clipboard: { writeText } })
  render(<ResultCard result={result(10)} shareUrl="http://x/drafts/1" />)

  await userEvent.click(screen.getByRole('button', { name: 'Copy share link' }))

  expect(writeText).toHaveBeenCalledWith('http://x/drafts/1')
  expect(screen.getByRole('button', { name: 'Link copied' })).toBeInTheDocument()
})

test('falls back to a prompt when the clipboard is unavailable', async () => {
  vi.stubGlobal('navigator', { clipboard: { writeText: () => Promise.reject(new Error('denied')) } })
  const prompt = vi.spyOn(window, 'prompt').mockImplementation(() => null)
  render(<ResultCard result={result(10)} shareUrl="http://x/drafts/1" />)

  await userEvent.click(screen.getByRole('button', { name: 'Copy share link' }))

  expect(prompt).toHaveBeenCalledWith('Copy this link to share your run:', 'http://x/drafts/1')
})
