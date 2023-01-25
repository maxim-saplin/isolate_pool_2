The package provides APIs for creating and keeping active Dart isolates (an isolate pool) ready to receive requests, do the processing and provide results.

The best way to learn how to use the package is clone the repo, open it in VSCode, check the *test* folder and run unit tests.

## Use-case one
The pool can accept one-time requests (aka pooled jobs) mimicking Flutter's `compute()` method. But  instead of spawning a new isolate each time it will use one of the available active isolates from the pool. In order to do so you need to inherit `PooledJob` class, define whatever params are needed as class fields, override the job() method that will be executed on pooled isolate. Use `IsolatePool.scheduleJob()` and pass an instance of pooled job in order to get it transferred to another isolate, executed and result returned.

## Use-case two
The second way of using the APIs is to have an instance created in one of the pooled isolates and communicate with it via a proxy instance, It is kind of messaging from the main isolate to one of the isolates in a pool with multiple instances created in multiple isolates, messages and responses properly correlated and arranged via descendants of `Action`. You can wrap `PooledInstanceProxy` in a class and mimic RPC kind of communication with `PooledInstance` in external isolate.

```
                                                           │
                        Main isolate                       │  Isolate in the pool
                                                           │
                        ┌─────────────────────────────┐    │
Step 1 - Instantiate    │                             │    │     Pooled instance with params
a decendant of          │  PooledInstance             │    │     is passed to isolate within
PooledInstance          │                             │    │     the pool. init() method is
                        │    - Params                 │    │     called initializing whatever
                        │                             │    │     fileds necessary and creating
                        └──────────────┬──────────────┘    │     whatever objects required
                                       │                   │     (aka State)
                                   Passed to               │
                                       │                   │   ┌─────────────────────────────┐
                                       │                   │   │                             │
                        ┌──────────────┼──────────────┐    │   │  PooledInstance             │
Step 2 - Pass the       │              │              │    │   │                             │
PooledInstance to       │  IsolatePool │              │    │   │    - Params                 │
isolate pool, it        │              ▼         ┌────┼────┼───►        ▼                    │
will transfer the       │    - createInstance()──┘    │    │   │    - init()───┐             │
object (together with   │                             │    │   │               │             │
fields) to isolate and  └──────────────┬──────────────┘    │   │    - State ◄──┘             │
call init(). Returned                  │                   │   │                             │
                                    Returns                │   │    - receiveRemoteCall()    │
                                       │                   │   │              ▲              │
                                       │                   │   └──────────────┬──────────────┘
                        ┌──────────────▼──────────────┐    │                  │
Step 3 - use returned   │                             │    │                  │
PooledInstanceProxy     │  PooledInstanceProxy        │    │                  │
can be used to pass     │                             │    │                  │
actions to the          │    - callRemoteMethod() ◄───┼────┼──────────────────┘
instance in the pool    │                             │    │
                        └──────────────▲──────────────┘    │
                                       │                   │      Action descendants are
                                       │                   │      passed to isolates via proxy
                                       │                   │      instance in the main isolate.
                                       │                   │      Pooled instance uses switch
                        ┌──────────────┴──────────────┐    │      statement in receiveRemoteCall()
Create a set of         │                             │    │      processing requests and returning
Action descendants      │  Action                     │    │      results back to the requester
defininf pooled         │                             │    │
instance capabilities,  │    - Params                 │    │
use the with            │                             │    │
callMethodRemote()      └─────────────────────────────┘    │
                                                           │
```
