# ADR-010: Liskov Substitution

- Date: 2026-06-16
- Status: Accepted

## Context

The plugin pipeline relies on plugins being interchangeable. If a plugin violates its base class contract, the pipeline breaks silently.

## Decision

**Any subclass must be substitutable for its base without breaking the system.**

- All `GenerationPlugin` subclasses accept the same inputs (chunk grid + params) and produce the same kind of output (modified chunk grid). No plugin may require special handling by the pipeline.
- All terrain `Resource` definitions expose the same properties. The renderer doesn't branch on terrain type — it reads palette, density, etc. uniformly.
- A test plugin can replace any real plugin in the pipeline and the system still runs.

## Consequences

- Plugins cannot rely on being run in a specific position (though order affects output, any plugin must tolerate any grid state as input).
- No "special case" terrain types that require renderer changes.
- The test harness can substitute mock plugins to isolate behavior.
