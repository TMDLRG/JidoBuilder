# Next Steps

## Immediate

1. Convert `jido_builder_web` from plain Mix app to Phoenix LiveView app.
2. Add umbrella configuration (`dev/test/prod`) for Repo, PubSub, and runtime services.
3. Add initial `jido_builder_core` schemas + migrations for templates, agents, and audit logs.
4. Implement runtime service skeleton: hiring, signal dispatch, directive/state-op emitters.
5. Expand verification matrix into one row per capability from plan section 7.

## Deferred gap IDs

- `GAP-001`: Full Tier A-E UI workflows not yet implemented.
- `GAP-002`: Codegen block editor and compile queue not yet implemented.
- `GAP-003`: Optional integrations (LLM providers, Redis default mode) pending product decisions.
