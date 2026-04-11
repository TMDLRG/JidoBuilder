# Security Notes (Planned Controls)

- Generated modules are constrained to `builder/apps/jido_builder_generated/lib/**`.
- No user-authored Elixir source input: only curated block templates.
- Secrets management to be implemented in `jido_builder_core` with encrypted-at-rest fields.
- Codegen compile flow must be transactional (rollback on compile failure).
