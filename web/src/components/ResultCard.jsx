import { useState } from 'react'

// The title run: overall rating, record, and how each fight went.
export default function ResultCard({ result, shareUrl, onPlayAgain }) {
  const [copied, setCopied] = useState(false)

  async function share() {
    try {
      await navigator.clipboard.writeText(shareUrl)
      setCopied(true)
    } catch {
      window.prompt('Copy this link to share your run:', shareUrl)
    }
  }

  return (
    <section className={`result${result.undefeated ? ' result--undefeated' : ''}`} aria-label="Title run result">
      {result.undefeated && <p className="result__badge">Undefeated</p>}
      <p className="result__record">{result.record}</p>
      <p className="result__overall">
        Overall rating <strong>{result.overall}</strong>
      </p>

      <ol className="result__fights" aria-label="Fights">
        {result.fights.map((fight) => (
          <li key={fight.number} className={fight.won ? 'fight fight--won' : 'fight fight--lost'}>
            <span className="fight__number">Fight {fight.number}</span>
            <span className="fight__opponent">vs. {fight.opponent_rating}-rated opponent</span>
            <span className="fight__odds">{Math.round(fight.win_probability * 100)}% to win</span>
            <span className="fight__outcome">{fight.won ? 'W' : 'L'}</span>
          </li>
        ))}
      </ol>

      <div className="result__actions">
        <button type="button" className="button" onClick={share}>
          {copied ? 'Link copied' : 'Copy share link'}
        </button>
        {onPlayAgain && (
          <button type="button" className="button button--primary" onClick={onPlayAgain}>
            Play again
          </button>
        )}
      </div>
    </section>
  )
}
