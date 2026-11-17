import { Link, useNavigate } from 'react-router'
import { useSession } from '../auth/SessionContext.jsx'

export default function AccountMenu() {
  const { user, loading, signOut } = useSession()
  const navigate = useNavigate()

  if (loading) return null
  if (!user) {
    return (
      <Link to="/sign-in" className="account__link">
        Sign in
      </Link>
    )
  }

  return (
    <span className="account">
      <span className="account__name">{user.display_name}</span>
      <button
        type="button"
        className="account__signout"
        onClick={async () => {
          await signOut()
          navigate('/')
        }}
      >
        Sign out
      </button>
    </span>
  )
}
