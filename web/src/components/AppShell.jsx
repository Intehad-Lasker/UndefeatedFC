import { Link, NavLink, Outlet } from 'react-router'
import AccountMenu from './AccountMenu.jsx'

export default function AppShell() {
  return (
    <div className="shell">
      <header className="shell__header">
        <Link to="/" className="shell__logo">
          Undefeated<span>FC</span>
        </Link>
        <nav className="shell__nav" aria-label="Main">
          <NavLink to="/" end>
            Play
          </NavLink>
          <NavLink to="/fighters">Fighters</NavLink>
          <NavLink to="/leaderboard">Leaderboard</NavLink>
          <AccountMenu />
        </nav>
      </header>
      <main className="shell__main">
        <Outlet />
      </main>
      <footer className="shell__footer">Fight data from UFCStats. Not affiliated with the UFC.</footer>
    </div>
  )
}
