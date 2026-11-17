import { Link, NavLink, Outlet } from 'react-router'

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
        </nav>
      </header>
      <main className="shell__main">
        <Outlet />
      </main>
      <footer className="shell__footer">Fight data from UFCStats. Not affiliated with the UFC.</footer>
    </div>
  )
}
