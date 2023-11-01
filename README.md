The package provides APIs for creating and keeping active Dart isolates (an isolate pool) ready to receive requests, do the processing and provide results.

The best way to learn how to use the package is to check the provided `/example`... Or clone the repo, open it in VSCode and run unit tests.

## Use-case one - Pooled Jobs, aka Request-Response
The pool can accept one-time requests (pooled jobs) mimicking Flutter's `compute()` method. But  instead of spawning a new isolate each time it will use one of the available active isolates from the pool. In order to do so you need to inherit `PooledJob` class, define whatever params are needed as class fields, override the `job()` method that will be executed on pooled isolate. Use `IsolatePool.scheduleJob()` and pass an instance of pooled job in order to get it transferred to another isolate, executed and result returned.

## Use-case two - persistant remote objects, aka pooled instances
The second way of using the APIs is to have an instance created in one of the pooled isolates and communicate with it via a proxy instance, It is kind of messaging from the main isolate to one of the isolates in a pool with multiple instances created in multiple isolates, messages and responses properly correlated and arranged via descendants of `Action`. You can wrap `PooledInstanceProxy` in a class and mimic RPC kind of communication with `PooledInstance` in external isolate.

## Pooled Instance - How it works
![Diagram](https://github.com/maxim-saplin/isolate_pool_2/assets/7947027/1066382f-58c6-4470-b907-1b0f01c816f5)
