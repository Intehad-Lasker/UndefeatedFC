// The six skill slots. Filled slots show the fighter and their rating, which is
// revealed only now. With a fighter selected, every empty slot becomes a button
// that drafts them into it.
export default function SlotBoard({ slots, skills, selectedFighter, onPick, disabled, lastPickSlot }) {
  const descriptions = Object.fromEntries((skills ?? []).map((skill) => [skill.key, skill.description]))

  return (
    <ol className="slots" aria-label="Your build">
      {slots.map((slot) => {
        const canPick = !slot.fighter && selectedFighter && !disabled
        return (
          <li key={slot.key} className={`slot${slot.fighter ? ' slot--filled' : ''}${slot.key === lastPickSlot ? ' slot--revealed' : ''}`}>
            <div className="slot__label">{slot.label}</div>
            {slot.fighter ? (
              <>
                <div className="slot__fighter">{slot.fighter.name}</div>
                <div className="slot__rating" aria-label={`${slot.label} rating`}>
                  {slot.rating}
                </div>
              </>
            ) : canPick ? (
              <button type="button" className="button slot__pick" onClick={() => onPick(slot.key)}>
                Put {selectedFighter.name} here
              </button>
            ) : (
              <div className="slot__hint">{descriptions[slot.key] ?? 'Empty'}</div>
            )}
          </li>
        )
      })}
    </ol>
  )
}
