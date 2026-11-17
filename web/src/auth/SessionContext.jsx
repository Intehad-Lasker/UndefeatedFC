import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react'
import { api } from '../api/client.js'

// Who is signed in, shared by the header and every page. The server's session
// cookie is the source of truth; this only mirrors it for rendering.
const SessionContext = createContext(null)

export function SessionProvider({ children }) {
  const [user, setUser] = useState(undefined) // undefined while loading, null when signed out

  useEffect(() => {
    api
      .currentSession()
      .then(({ user }) => setUser(user))
      .catch(() => setUser(null))
  }, [])

  const signIn = useCallback(async (emailAddress, password) => {
    const { user } = await api.signIn(emailAddress, password)
    setUser(user)
    return user
  }, [])

  const signUp = useCallback(async (details) => {
    const { user } = await api.signUp(details)
    setUser(user)
    return user
  }, [])

  const signOut = useCallback(async () => {
    await api.signOut()
    setUser(null)
  }, [])

  const value = useMemo(() => ({ user, loading: user === undefined, signIn, signUp, signOut }), [user, signIn, signUp, signOut])
  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
}

export function useSession() {
  const session = useContext(SessionContext)
  if (!session) throw new Error('useSession must be used inside <SessionProvider>')
  return session
}
