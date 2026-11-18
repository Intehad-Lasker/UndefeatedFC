import { useState } from 'react'
import { useParams } from 'react-router'
import MatchRoom from '../match/MatchRoom.jsx'
import { useMatch } from '../match/useMatch.js'

function InviteLink() {
  const [copied, setCopied] = useState(false)
  const url = window.location.href

  async function copy() {
    try {
      await navigator.clipboard.writeText(url)
      setCopied(true)
    } catch {
      window.prompt('Send this link to your opponent:', url)
    }
  }

  return (
    <div className="invite">
      <p>Send this link to your opponent. The match starts when they open it and join.</p>
      <code className="invite__url">{url}</code>
      <button type="button" className="button" onClick={copy}>
        {copied ? 'Link copied' : 'Copy invite link'}
      </button>
    </div>
  )
}

export default function MatchPage() {
  const { matchId } = useParams()
  const { match, error, join, pick } = useMatch(matchId)

  if (!match) {
    return error ? (
      <p role="alert" className="error">
        {error}
      </p>
    ) : (
      <p className="loading">Loading match…</p>
    )
  }

  const host = match.players.find((player) => player.seat === 1)

  return (
    <section className="match">
      <h1>Head-to-head</h1>
      {match.status === 'waiting' && match.your_seat === 1 && (
        <>
          <p className="notice" role="status">
            Waiting for an opponent…
          </p>
          <InviteLink />
        </>
      )}
      {match.status === 'waiting' && !match.your_seat && (
        <div className="invite">
          <p>
            <strong>{host?.display_name}</strong> challenged you to a draft: six shared spins, alternating picks, then
            your builds fight.
          </p>
          <button type="button" className="button button--primary" onClick={join}>
            Join the match
          </button>
        </div>
      )}
      {match.status !== 'waiting' && (
        <>
          <p className="notice">{match.players.map((player) => player.display_name).join(' vs. ')}</p>
          <MatchRoom match={match} onPick={pick} />
        </>
      )}
      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
    </section>
  )
}
