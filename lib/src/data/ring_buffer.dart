/// Fixed-capacity FIFO that overwrites its oldest element when full.
/// Iteration order is oldest to newest.
class RingBuffer<T> extends Iterable<T> {
  RingBuffer(this.capacity)
      : assert(capacity > 0),
        _slots = List<T?>.filled(capacity, null);

  final int capacity;
  final List<T?> _slots;
  int _start = 0;
  int _length = 0;

  @override
  int get length => _length;

  bool get isFull => _length == capacity;

  void add(T value) {
    final index = (_start + _length) % capacity;
    _slots[index] = value;
    if (_length == capacity) {
      _start = (_start + 1) % capacity;
    } else {
      _length++;
    }
  }

  void clear() {
    for (var i = 0; i < capacity; i++) {
      _slots[i] = null;
    }
    _start = 0;
    _length = 0;
  }

  T operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    return _slots[(_start + index) % capacity] as T;
  }

  @override
  Iterator<T> get iterator =>
      Iterable<T>.generate(_length, (i) => this[i]).iterator;
}
