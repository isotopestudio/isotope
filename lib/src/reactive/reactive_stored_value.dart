import 'dart:async';
import 'package:isotope/src/reactive/reactive.dart';
import 'package:isotope/src/reactive/reactive_value.dart';

class ReactiveStoredValue<T> implements ReactiveValue<T> {
  T _value;
  T get value => _value;
  final _change = new StreamController<Change<T>>();
  set value(T val) {
    if (_value == val) return;
    T old = _value;
    _value = val;
    _change.add(Change<T>(val, old, _curBatch));
  }

  int _curBatch = 0;

  ReactiveStoredValue({T initial}) : _value = initial {
    _onChange = _change.stream.asBroadcastStream();
  }

  void setCast(dynamic /* T */ val) => value = val;

  Stream<Change<T>> _onChange;

  Stream<Change<T>> get onChange {
    _curBatch++;
    final ret = StreamController<Change<T>>();
    ret.add(Change<T>(value, null, _curBatch));
    ret.addStream(_onChange.skipWhile((v) => v.batch < _curBatch));
    return ret.stream.asBroadcastStream();
  }

  Stream<T> get values => onChange.map((c) => c.neu);

  void bind(ReactiveValue<T> reactive) {
    value = reactive.value;
    reactive.values.listen((v) => value = v);
  }

  void bindStream(Stream<T> stream) => stream.listen((v) => value = v);

  void bindOrSet(/* T | Stream<T> | Reactive<T> */ other) {
    if (other is ReactiveValue<T>) {
      bind(other);
    } else if (other is Stream<T>) {
      bindStream(other.cast<T>());
    } else {
      value = other;
    }
  }

  StreamSubscription<T> listen(ReactiveValueCallback<T> callback) =>
      values.listen(callback);

  Stream<R> map<R>(R mapper(T data)) => values.map(mapper);
}
