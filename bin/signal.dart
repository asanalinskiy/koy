import 'dart:async';

class KoySignal<T> {
  T _value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  KoySignal(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      _controller.add(_value);
    }
  }

  StreamSubscription<T> listen(Function(T) callback) {
    return _controller.stream.listen((val) => callback(val));
  }

  @override
  String toString() => 'KoySignal($value)';
}
