import { createConsumer } from '@rails/actioncable'

// One WebSocket per tab, opened the first time something subscribes. /cable is
// served by Rails (proxied by Vite in development), on the same origin, so the
// session cookie identifies signed-in players.
let consumer = null

export function subscribe(channel, params, onMessage) {
  consumer ??= createConsumer('/cable')
  const subscription = consumer.subscriptions.create({ channel, ...params }, { received: onMessage })
  return () => subscription.unsubscribe()
}
