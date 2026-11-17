import { Link } from 'react-router'

export default function NotFoundPage() {
  return (
    <section className="not-found">
      <h1>Nothing here</h1>
      <p>That page doesn't exist.</p>
      <Link to="/">Back to the game</Link>
    </section>
  )
}
