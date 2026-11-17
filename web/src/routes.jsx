import AppShell from './components/AppShell.jsx'
import DraftPage from './pages/DraftPage.jsx'
import HomePage from './pages/HomePage.jsx'
import NotFoundPage from './pages/NotFoundPage.jsx'

// Shared by the browser router (main.jsx) and memory routers in tests.
export const routes = [
  {
    path: '/',
    element: <AppShell />,
    errorElement: <NotFoundPage />,
    children: [
      { index: true, element: <HomePage /> },
      { path: 'drafts/:draftId', element: <DraftPage /> },
      { path: '*', element: <NotFoundPage /> },
    ],
  },
]
