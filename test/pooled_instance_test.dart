// ignore_for_file: no_leading_underscores_for_local_identifiers
@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';

class ValueHolder extends PooledInstance {
  String initialValue;
  ValueHolder(this.initialValue);

  late List<String> _values;

  @override
  Future init() async {
    _values = [initialValue];
  }

  @override
  Future<dynamic> receiveRemoteCall(Action action) async {
    switch (action) {
      case GetValues _:
        return _values;
      case SetValue _:
        var v = action.value;
        _values.add(v);
        return;
      default:
        throw 'Unknown action ${action.runtimeType}';
    }
  }
}

class GetValues extends Action {}

class SetValue extends Action {
  final String value;

  SetValue(this.value);
}

class UnknownAction extends Action {}

void main() {
  test('Pooled isnatce is put to pool and responds', () async {
    var p = IsolatePool(2);
    await p.start();
    var pi = ValueHolder('Hello');
    var px = await p.addInstance(pi);
    var r = await px.callRemoteMethod<List<String>>(GetValues());

    expect(r[0], 'Hello');

    await px.callRemoteMethod(SetValue('world'));
    r = await px.callRemoteMethod<List<String>>(GetValues());

    expect(r[0], 'Hello');
    expect(r[1], 'world');
  });

  test('Pooled isnatce throws when receving unknown action', () async {
    var p = IsolatePool(3);
    await p.start();
    var pi = ValueHolder('Hello');
    var px = await p.addInstance(pi);
    var r = await px.callRemoteMethod<List<String>>(GetValues());

    expect(r[0], 'Hello');

    expect(px.callRemoteMethod(UnknownAction()),
        throwsA("Unknown action UnknownAction"));
  });

  test('Pooled isnatce can be destroyed', () async {
    var p = IsolatePool(3);
    await p.start();
    var pi = ValueHolder('Hello');
    var px = await p.addInstance(pi);
    var r = await px.callRemoteMethod<List<String>>(GetValues());

    expect(r[0], 'Hello');

    p.destroyInstance(px);

    expect(
        () => px.callRemoteMethod(GetValues()),
        throwsA(isA<NoSuchIsolateInstance>()));
  });
}
