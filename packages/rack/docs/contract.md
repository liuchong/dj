# Runtime contract

## Context and services

`createContext(options?)` constructs a pure in-memory root. `options.onError`
observes lifecycle failures; it is not an alternate success channel. A context
offers `provide(name,value,check?)`, `get(name,strict?)`, `plugin(plugin,config?)`,
`inject(dependencies,callback)`, `extend(metadata?)`, `isolate(name,label?)`, and
`intercept(name,config)`. Services have one provider in each isolation scope.
Duplicate providers and conflicting computed-property declarations fail.
Direct service property reads require a declared or inherited dependency;
`get()` explicitly probes optional services. A provider can use and update its
own service during initialization. Only that provider may update its value.

Each plugin is a function, a constructor, or an object with `apply(ctx,config)`.
`inject` accepts service names or a name-to-intercept-config map. `Config` may
provide a synchronous Standard Schema validator. Validation and startup failures
are observable and never become successful activation. JavaScript consumers can
subclass `Service`; Eliscript consumers can use `createService` without requiring
host class syntax. Tracker metadata preserves the invoking plugin's resource
ownership while a service method resolves its declared dependencies.

## Plugin state and ownership

Each activation has a fiber with `uid`, `name`, `ctx`, `rawConfig`,
`effectiveConfig`, `inject`, `state`, and `error`. Methods are `await`, `effect`,
`update`, `restart`, `dispose`, `resolveConfig`, and `getEffects`. The awaitable
plugin handle resolves to the non-thenable fiber. States are pending, loading,
active, unloading, failed, and disposed. Missing dependencies leave a plugin
pending; provider loss unloads dependents, and restoration activates them again.
Replacing a provider cannot leave a consumer active against its old dependency.

`effect(setup,label?)` acquires a resource immediately. Setup may return a cleanup
function, a promise, or a synchronous/asynchronous iterator of cleanup functions.
Ownership is installed before setup, including reentrant disposal and partial
initialization failure. Disposal joins acquisition and any existing cleanup.
Registration on an unloading or disposed owner is rejected. Related cleanup
steps inside one effect run in reverse collection order and await each other;
independent effects can clean up concurrently. Cleanup must release children,
listeners, watchers and timers before an owning application closes shared state.
Unregistered ambient resources remain the plugin's responsibility.

## Events

`on` and `once` return owned disposers. `prepend` changes listener priority;
`global` bypasses a dispatch receiver's `symbols.filter` predicate. Each dispatch
uses a listener snapshot. An explicit object/function first argument is the
listener receiver. `emit` is synchronous notification; `parallel` awaits all
listeners and aggregates errors; `serial` awaits listeners in order until a
non-null/non-undefined/non-false result; `bail` is its synchronous counterpart.
`waterfall` composes around a final continuation, allowing a listener to stop the
chain. Plugin-specific update hooks do not intercept another plugin's update.

## Configuration composition

`createLoader(context,{resolve?})` mounts ordered entries with stable `id`,
`plugin` or module `name`, `config`, `disabled`, `isolate`, and nested `plugins`.
The resolver is injectable; the default uses native dynamic imports. Complete
candidate module resolution precedes mutation of the running tree. Config-only
changes update existing fibers, removed/disabled entries unload, and replacement
modules create new fibers. Apply operations are serialized; failure does not
silently mark the whole tree healthy. A failed activation is reported and remains
inspectable. Patches replace entry configuration, insert entries, or remove them;
every inserted id is immediately available to later patches.

`settle()` waits for current lifecycle operations, not for missing dependencies
to appear. `inspect()` returns plugin names, states, dependency names, resource
counts and bounded error summaries. It does not return configuration or secrets.
Logger exporters are owned resources; duplicate exporter registrations remain
independent. Named loggers honor exporter severity thresholds, custom formatters
and line limits.

Code-module replacement is controlled by the host resolver, not by reading engine
private caches. A host may supply a new module identity and reapply the tree.

## Acceptance inventory

- [x] R01 dependency arrival, loss, replacement and failed activation.
- [x] R02 isolated providers, inherited dependencies and tracked service calls.
- [x] R03 resource acquisition races, failure rollback and idempotent async cleanup.
- [x] R04 all event modes, receiver filtering, update interception and once.
- [x] R05 configuration validation, nested composition, patches and replacement.
- [x] R06 independent real server/timer/storage lifecycle and clean shutdown.

- [x] R07 logger exporters, formatting, computed properties and service mixins.

Acceptance runs use real ephemeral HTTP and SQLite resources, plus an in-memory
plugin graph. They do not contact external accounts. Missing-service waiting is
not a startup error, and `settle()` does not wait indefinitely for such services.
Resource release retains each activation's dependency references until its
cleanup has settled, even if a provider has already been unpublished.

This contract describes the runtime itself. It does not claim native engine
module-cache eviction, a filesystem compiler, process isolation, or support for
all third-party extensions. A module resolver is a host integration boundary.

## Public state and exact boundaries

`FiberState` is the numeric table `PENDING=0`, `LOADING=1`, `ACTIVE=2`,
`FAILED=3`, `DISPOSED=4`, `UNLOADING=5`. Human diagnostics from `inspect()` use
lowercase names. A fiber's `parent` is its parent context; `runtime` is shared
by identical callbacks and owns the callback, name, schema and live fiber list.
`store` retains the activation's implementation records through cleanup, then
becomes undefined. `inertia` exposes the current lifecycle transition.

`get(name)` tests provider activation, independently of its readiness predicate.
Only dependency refresh evaluates readiness; explicit `reflect.notify(names)`
refreshes matching consumers and returns them. Direct root reads can see a
loading provider; injected plugin reads retain their activation snapshot.
Services may forward associated computed members using their tracker metadata.
Context extension preserves all own descriptors, symbols and the actual parent
prototype. Symbols, underscore-prefixed names, numeric strings, `prototype` and
`then` bypass service lookup.

`update(raw,noSave=false)` retains raw input before resolution, validation or
update interception. A configuration hook cannot bypass schema validation.
A veto preserves the current effective config, not the rejected raw input.
Pending updates resolve on activation. Updates return undefined; use `await()`
to join a transition. `restart()` joins cleanup and reactivation. Plugin
notifications observe the initial pending state and final removal; a failing
teardown observer cannot prevent resource cleanup. Root `fiber.dispose()`
releases root resources while leaving the root usable; `context.dispose()` is
final application shutdown.

Effect setup runs with its fiber as receiver. A synchronous cleanup runs before
its disposer returns. Repeated public disposal is a no-op; the structural owner
still joins asynchronous cleanup already started by another caller. Promises
may resolve to a function or a nullish value; iterable setup may yield cleanup
functions and return a final cleanup. Asynchronous iteration checks ownership
before its next step. A cleanup error stops later steps in that effect while
other independently owned resources still release. Metadata reports labels and
nested effects without internal activation bookkeeping.

Event callbacks receive receiver and arguments traced to the listener context.
An explicit null receiver is valid. `internal/listener` can intercept registration;
local update hooks precede global hooks. Once listeners detach before callback
invocation. Listener removal after a dispatch snapshot does not cancel that
snapshot. Waterfall continuations receive the payload arguments and next hook.

Logger intercepts resolve at call time. Exporter messages are independent objects,
with a shared sequence and timestamp per log call; exporter mutation cannot
change another exporter's message fields. Level zero is a valid threshold.
Logger buffers, exporter registrations, recursive causes and aggregate errors
remain observable. The package exports the built-in service constructors,
`Fiber`, `RackError`, `ValidationError`, tracking, callable, stack and type helpers.


## Expanded acceptance inventory

- [x] R08 descriptor-preserving context prototypes, symbols, reserved keys and branding.
- [x] R09 readiness-only dependency checks, optional reads, shared isolation and loading visibility.
- [x] R10 raw/effective config separation, hook validation, local veto and pending updates.
- [x] R11 synchronous cleanup, structural async joins, partial iterator rollback and cancelled startup.
- [x] R12 listener interception, traced arguments, snapshot removal and waterfall payloads.
- [x] R13 initial/removal notifications, runtime identity and failing teardown observers.
- [x] R14 dynamic logger intercepts, detached methods, exporter isolation and zero thresholds.
- [x] R15 atomic mixin failure, associated members and rejected computed-property writes.
- [x] R16 direct fibers, root lifetime, callable helpers and method-decorator ownership.
- [x] R17 isolated cleanup failure, cancelled async iteration and no-read label allocation.

These checks exercise public behavior through interacting plugins, services,
resources and the host boundary. The application integration additionally checks
operator-visible module status, persistent message deduplication, reply routing,
port draining and final database shutdown. Runtime extensions outside this
contract remain separate host integrations.
