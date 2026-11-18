import { SessionProvider } from './auth/SessionContext.jsx'
import AppShell from './components/AppShell.jsx'
import DraftPage from './pages/DraftPage.jsx'
import FighterPage from './pages/FighterPage.jsx'
import FightersPage from './pages/FightersPage.jsx'
import ForgotPasswordPage from './pages/ForgotPasswordPage.jsx'
import HomePage from './pages/HomePage.jsx'
import LeaderboardPage from './pages/LeaderboardPage.jsx'
import MatchPage from './pages/MatchPage.jsx'
import MyDraftsPage from './pages/MyDraftsPage.jsx'
import NotFoundPage from './pages/NotFoundPage.jsx'
import SignInPage from './pages/SignInPage.jsx'
import SignUpPage from './pages/SignUpPage.jsx'

// Shared by the browser router (main.jsx) and memory routers in tests.
export const routes = [
  {
    path: '/',
    element: (
      <SessionProvider>
        <AppShell />
      </SessionProvider>
    ),
    errorElement: <NotFoundPage />,
    children: [
      { index: true, element: <HomePage /> },
      { path: 'drafts/:draftId', element: <DraftPage /> },
      { path: 'fighters', element: <FightersPage /> },
      { path: 'fighters/:fighterId', element: <FighterPage /> },
      { path: 'leaderboard', element: <LeaderboardPage /> },
      { path: 'matches/:matchId', element: <MatchPage /> },
      { path: 'me/drafts', element: <MyDraftsPage /> },
      { path: 'sign-in', element: <SignInPage /> },
      { path: 'sign-up', element: <SignUpPage /> },
      { path: 'forgot-password', element: <ForgotPasswordPage /> },
      { path: '*', element: <NotFoundPage /> },
    ],
  },
]
