# Rack

Rack is an independent plugin composition and resource lifecycle package written
in Eliscript. It has no application-specific routing, storage or model behavior.
Applications provide capabilities; plugins declare dependencies and own their
registrations and cleanup.

The public entry exports `Context`, `createContext`, `Service`, `createService`,
`Inject`, `FiberState`, `symbols`, `Logger`, `LoggerLevel`, logging formatters,
`DisposableList`, `withProps`, and prototype helpers. The loader
entry exports `createLoader`, `validateEntries`, and `applyEntryPatches`.

```elisp
(module example.app
  (import "./src/index.eli" createContext)
  (defconst app (createContext))
  (js-call app :provide "clock" (js-object :now (lambda () (Date/now))))
  (defconst feature (js-call app :plugin
    (js-object :name "feature" :inject (js-array "clock")
      :apply (lambda (ctx config)
        (js-call ctx :on "request" (lambda (value) (console/log value)))))))
  (await feature)
  (js-call app :emit "request" "ready")
  (await (js-call app :dispose)))
```

See [the contract](docs/contract.md) for activation, scope, event and teardown
semantics. Build `eliscript.json` with an installed Eliscript compiler. Commit
source, not generated modules. A host that compiles a larger source tree may
import `src/index.eli` directly without a separate package build.

Plugin code executes in the host process. Service scopes are dependency scopes,
not operating-system sandboxes. Releasing a listener or a connection cannot undo
an already committed external action. Applications retain their transaction,
drain and persistence protocols.

## Standalone use

From this package directory, `npm run build` compiles only `src/` using the
installed language compiler. `npm run build:test` compiles the package's own
acceptance sources; `npm test` runs those products with Bun. These commands do not
load an application, configuration account, or business database. JavaScript is
emitted into ignored build directories.

The package is covered by the [1PL license](LICENSE). Its public behavior and
verified boundaries are recorded in [the runtime contract](docs/contract.md).
