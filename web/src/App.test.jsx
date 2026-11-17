import { render, screen } from '@testing-library/react'
import { expect, test } from 'vitest'
import App from './App.jsx'

test('renders the game title', () => {
  render(<App />)

  expect(screen.getByRole('heading', { name: 'UndefeatedFC' })).toBeInTheDocument()
})
