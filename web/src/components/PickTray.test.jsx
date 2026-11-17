import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, test, vi } from 'vitest'
import PickTray from './PickTray.jsx'

const openSlots = [
  { key: 'power', label: 'Power' },
  { key: 'chin', label: 'Chin' },
]

test('renders nothing until a fighter is selected', () => {
  const { container } = render(<PickTray fighter={null} openSlots={openSlots} onPick={() => {}} />)

  expect(container).toBeEmptyDOMElement()
})

test('offers one button per open slot', async () => {
  const onPick = vi.fn()
  render(<PickTray fighter={{ id: 7, name: 'Ace Ardent' }} openSlots={openSlots} onPick={onPick} />)

  expect(screen.getByRole('region', { name: 'Draft the selected fighter' })).toHaveTextContent('Draft Ace Ardent as')
  await userEvent.click(screen.getByRole('button', { name: 'Chin' }))

  expect(onPick).toHaveBeenCalledWith('chin')
  expect(screen.getAllByRole('button')).toHaveLength(2)
})
