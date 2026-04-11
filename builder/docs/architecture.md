# Builder Architecture (Bootstrap)

## Umbrella layout

- `builder/apps/jido_builder_core`: persistence/domain contexts (planned).
- `builder/apps/jido_builder_runtime`: runtime wrappers and dynamic agent execution (planned).
- `builder/apps/jido_builder_codegen`: block templates + compile queue (planned).
- `builder/apps/jido_builder_generated`: destination app for generated modules (planned).
- `builder/apps/jido_builder_web`: UI host and supervision root (planned).

## Dependency intent

- Every app has path dependency on upstream `:jido` via `{:jido, path: "../../..", override: true}`.
- `web -> runtime/core/codegen`.
- `runtime -> core`.
- `codegen -> core/generated`.

## Next architecture increment

1. Introduce Phoenix + LiveView in `jido_builder_web`.
2. Introduce Ecto/Cloak/PubSub in `jido_builder_core` and umbrella config.
3. Implement runtime adapter boundary in `jido_builder_runtime`.
