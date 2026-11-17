import { useEffect, useMemo } from 'react'
import './SpinWheels.css'

const SPIN_MS = 1800
const LAPS = 4

function prefersReducedMotion() {
  return typeof window.matchMedia !== 'function' || window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

// One reel. While spinning it scrolls continuously; when the server's result
// arrives it eases to that item. The server already decided where it lands.
function Reel({ label, items, targetId, spinning }) {
  const targetIndex = items.findIndex((item) => item.id === targetId)
  const strip = useMemo(() => Array.from({ length: LAPS + 1 }, () => items).flat(), [items])
  const landed = targetIndex >= 0 && !spinning
  const offset = landed ? LAPS * items.length + targetIndex : 0

  return (
    <div className="reel" aria-label={label}>
      <span className="reel__label">{label}</span>
      <div className="reel__window">
        <ul
          className={`reel__strip${spinning ? ' reel__strip--spinning' : ''}${landed ? ' reel__strip--landed' : ''}`}
          style={{ '--offset': offset, '--spin-ms': `${SPIN_MS}ms` }}
          aria-hidden="true"
        >
          {strip.map((item, index) => (
            <li key={`${item.id}-${index}`}>{item.name}</li>
          ))}
        </ul>
      </div>
      <output className="reel__result">{landed ? items[targetIndex].name : spinning ? 'Spinning…' : '—'}</output>
    </div>
  )
}

export default function SpinWheels({ weightClasses, eras, result, spinning, revealing, onRevealed }) {
  useEffect(() => {
    if (!revealing) return undefined
    const timer = setTimeout(onRevealed, prefersReducedMotion() ? 0 : SPIN_MS)
    return () => clearTimeout(timer)
  }, [revealing, onRevealed])

  return (
    <div className="wheels">
      <Reel label="Weight class" items={weightClasses} targetId={result?.weightClassId} spinning={spinning} />
      <Reel label="Era" items={eras} targetId={result?.eraId} spinning={spinning} />
    </div>
  )
}
