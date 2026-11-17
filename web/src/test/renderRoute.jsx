import { render } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { routes } from '../routes.jsx'

// Renders the real route tree at a URL, so tests exercise routing too.
export function renderRoute(path, extraRoutes = []) {
  const router = createMemoryRouter([...extraRoutes, ...routes], { initialEntries: [path] })
  return { router, ...render(<RouterProvider router={router} />) }
}
