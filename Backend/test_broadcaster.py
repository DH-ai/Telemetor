from broadcaster import Broadcaster


def drain(queue):
    items = []
    while not queue.empty():
        items.append(queue.get_nowait())
    return items


def test_every_subscriber_gets_the_full_stream():
    broadcaster = Broadcaster()
    _, q1 = broadcaster.subscribe()
    _, q2 = broadcaster.subscribe()

    for i in range(5):
        broadcaster.publish(['row', str(i)])

    assert drain(q1) == [['row', str(i)] for i in range(5)]
    assert drain(q2) == [['row', str(i)] for i in range(5)]
    assert broadcaster.published_count == 5


def test_unsubscribe_stops_delivery():
    broadcaster = Broadcaster()
    sid, queue = broadcaster.subscribe()
    broadcaster.publish(['a'])
    broadcaster.unsubscribe(sid)
    broadcaster.publish(['b'])

    assert drain(queue) == [['a']]
    assert broadcaster.subscriber_count == 0


def test_late_subscriber_only_sees_new_items():
    broadcaster = Broadcaster()
    broadcaster.publish(['old'])
    _, queue = broadcaster.subscribe()
    broadcaster.publish(['new'])

    assert drain(queue) == [['new']]


def test_slow_subscriber_drops_oldest_not_newest():
    broadcaster = Broadcaster(max_queue_size=3)
    _, queue = broadcaster.subscribe()

    for i in range(5):
        broadcaster.publish(i)

    assert drain(queue) == [2, 3, 4]


def test_listeners_receive_every_item_and_failures_are_isolated():
    broadcaster = Broadcaster()
    seen = []
    broadcaster.add_listener(seen.append)
    broadcaster.add_listener(lambda item: 1 / 0)  # must not break the stream
    _, queue = broadcaster.subscribe()

    broadcaster.publish('x')
    broadcaster.publish('y')

    assert seen == ['x', 'y']
    assert drain(queue) == ['x', 'y']
