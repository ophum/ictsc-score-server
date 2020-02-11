import { NativeEventSource, EventSourcePolyfill } from 'event-source-polyfill'
const EventSource = NativeEventSource || EventSourcePolyfill
const EndPoint = '/push'

// events: [String] 購読するイベント名の配列
function subscribe(events, onMessage) {
  console.log('call subscribeEventSource')

  const url = `${EndPoint}/?eventType=${events.join(',')}`
  const eventSource = new EventSource(url, { withCredentials: true })

  eventSource.onmessage = e => {
    onMessage(JSON.parse(e.data).data)
  }

  // eventSource.onopen = e => {
  //   console.log('eventsource connected')
  // }

  eventSource.onerror = e => {
    console.error('error', e)
    $nuxt.notifyError({
      message:
        'Push通知と自動リロードが停止しました\nページをリロードしてください'
    })
    // net::ERR_INCOMPLETE_CHUNKED_ENCODING, net::ERR_EMPTY_RESPONSE
  }

  return eventSource
}

export default ({ app }, inject) => inject('eventSource', { subscribe })
