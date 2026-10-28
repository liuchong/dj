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
