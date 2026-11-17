// On phones the slot board sits above a long pool, so after choosing a fighter
// near the bottom the player would have to scroll back up to place them. This
// tray stays pinned to the bottom of the screen with one button per open slot.
// Wide screens hide it with CSS: their slot board is already in view.
export default function PickTray({ fighter, openSlots, onPick }) {
  if (!fighter) return null

  return (
    <div className="pick-tray" role="region" aria-label="Draft the selected fighter">
      <p className="pick-tray__title">
        Draft <strong>{fighter.name}</strong> as
      </p>
      <div className="pick-tray__slots">
        {openSlots.map((slot) => (
          <button key={slot.key} type="button" className="button" onClick={() => onPick(slot.key)}>
            {slot.label}
          </button>
        ))}
      </div>
    </div>
  )
}
