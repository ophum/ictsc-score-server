import { NativeEventSource, EventSourcePolyfill } from 'event-source-polyfill'
const EventSource = NativeEventSource || EventSourcePolyfill
const EndPoint = '/push'

// events: [String] 購読するイベント名の配列
function subscribe(events, onMessage) {
  // logout時など
  if (!events) {
    return
  }

  const url = `${EndPoint}/?eventType=${events.join(',')}`
  const eventSource = new EventSource(url, { withCredentials: true })

  eventSource.onmessage = (e) => {
    onMessage(JSON.parse(e.data).data)
  }

  // eventSource.onopen = e => {
  //   console.log('eventsource connected')
  // }

  eventSource.onerror = (error) => {
    console.error(error)
    error.target.close()

    // firefoxではリロード時に通知が表示されてしまうため対処
    setTimeout(() => {
      $nuxt.$nextTick(() => {
        // $nuxt.notifyWarning({
        //   timeout: 0,
        //   message:
        //     'Push通知と自動更新が停止しました\nページをリロードしてください',
        // })

        // 接続が切れたら再接続する
        // 無限ループの可能性があるので良くないが1秒間隔なので一先ずセーフ
        subscribe(events, onMessage)
      })
    }, 1000)
  }

  return eventSource
}

export default ({ app }, inject) => inject('eventSource', { subscribe })
