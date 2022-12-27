import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:isolate_pool_2/isolate_pool_2.dart';

class RandomBytesGenerator extends PooledInstance {
  late Random _rand;

  @override
  Future init() async {
    _rand = Random();
  }

  RandomBytes getBytes(int n) {
    // var items = List<int>.filled(n, _rand.nextInt(255));
    var items = [Uint8List(n)];
    for (var i = 0; i < n; i++) {
      items[0][i] = _rand.nextInt(256);
    }

    var min = 255;
    var max = 0;
    var avg = 0.0;

    for (var i = 0; i < items[0].length; i++) {
      if (items[0][i] < min) {
        min = items[0][i];
      }
      if (items[0][i] > max) {
        max = items[0][i];
      }
      avg += items[0][i];
    }

    avg /= items[0].length;

    var t = TransferableTypedData.fromList(items);
    return RandomBytes(t, items[0].length, min, max, avg);
  }

  @override
  Future<dynamic> receiveRemoteCall(Action action) async {
    switch (action.runtimeType) {
      case GetNBytesAction:
        return getBytes((action as GetNBytesAction).numberOfBytes);
      default:
        throw 'Unknown action ${action.runtimeType}';
    }
  }
}

class GetNBytesAction extends Action {
  final int numberOfBytes;
  GetNBytesAction(this.numberOfBytes);
}

class RandomBytes {
  final TransferableTypedData bytes;
  final int number;
  final int min;
  final int max;
  final double avg;

  RandomBytes(this.bytes, this.number, this.min, this.max, this.avg);
}

void main(List<String> arguments) async {
  var pool = IsolatePool(4);
  await pool.start();

  var proxies = List<PooledInstanceProxy>.empty(growable: true);

  for (var i = 0; i < 8; i++) {
    proxies.add(await pool.addInstance(RandomBytesGenerator()));
  }

  var futures = List<Future<RandomBytes>>.generate(
      8, (i) => proxies[i].callRemoteMethod(GetNBytesAction(1024 * 1024)));

  var results = await Future.wait(futures);

  for (var r in results) {
    print('Min: ${r.min}, Max: ${r.max}, Avg: ${r.avg.toStringAsFixed(1)},');
  }
}
