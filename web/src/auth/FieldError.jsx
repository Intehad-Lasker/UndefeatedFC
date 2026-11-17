export default function FieldError({ messages }) {
  if (!messages?.length) return null
  return <span className="field-error">{messages.join(' ')}</span>
}
