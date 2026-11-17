import { useEffect, useState } from 'react'
import { api } from './client.js'

// Game configuration (skills, weight classes, eras, rules) is fetched once per
// page load and shared by every component that asks for it.
let request = null

export function useMeta() {
  const [meta, setMeta] = useState(null)

  useEffect(() => {
    let active = true
    request ??= api.meta()
    request.then((data) => active && setMeta(data)).catch(() => (request = null))
    return () => {
      active = false
    }
  }, [])

  return meta
}

export function resetMetaForTests() {
  request = null
}
