# Engineering Standards

This document is the canonical engineering policy for this repository. It
applies equally to human contributors and coding agents. Agent-specific files
must point here instead of duplicating these rules.

## Definition of done

A change is complete only when:

- behavior is covered by tests appropriate to its risk;
- generated files are current;
- documentation is updated when a public workflow or contract changes;
- `make check` passes;
- no unrelated user changes are reverted or reformatted.

Use `make fix` for repository-supported mechanical fixes, then review every
result before keeping it. Never edit `*.g.dart` files manually.

## Supported platforms and environments

- The template supports Android and iOS only. Do not add `web`, `windows`,
  `linux`, or `macos` platform directories.
- Product environments are `dev`, `staging`, and `prod`. Flutter build modes
  are independently `debug`, `profile`, and `release`.
- Read compile-time environment values only in `lib/core/config/`. Application
  code consumes typed `AppConfig` values.
- Production builds must go through the release preflight commands documented
  in [release.md](release.md).

## Source structure

Place reusable application infrastructure in `lib/core/`, application shell
code in `lib/app/`, and product behavior in `lib/features/<feature>/`.

A feature may contain these layers:

- `domain/`: entities and business rules. It must not depend on Flutter,
  Riverpod, Dio, `data/`, `presentation/`, or `providers/`.
- `data/`: API clients, DTOs, persistence, and repository implementations. It
  must not depend on `presentation/`.
- `providers/`: dependency wiring and state ownership.
- `presentation/`: widgets and interaction logic. It must not access Dio,
  SharedPreferences, or FlutterSecureStorage directly.

Keep dependencies pointing inward. Cross-feature imports are acceptable only
for an intentional public domain contract; shared infrastructure belongs in
`core`, not in an arbitrary feature.

The AST-based `tool/architecture_check.dart` enforces the boundaries above and
the following adapter ownership:

- `logger` is owned by `lib/core/logging/`;
- `toastification` is owned by `lib/core/feedback/`, with app-shell setup in
  `lib/app/app.dart`;
- `flutter_secure_storage` is owned by its storage adapter;
- `shared_preferences` is limited to bootstrap, its provider, and its adapter.

When a boundary must change, update the architecture, checker, tests, and this
document together. Do not add a one-off exception merely to make CI pass.

## Dart and Flutter code

- Follow `analysis_options.yaml`; warnings are failures, not suggestions.
- Format with `dart format`. Keep imports ordered and remove unused code.
- Prefer immutable values, small focused types, and explicit return types.
- Do not use `dynamic`, unchecked casts, or `print` to bypass a proper model or
  service contract.
- Await futures. Use `unawaited(...)` only when fire-and-forget behavior is
  deliberate and failures are handled by the called boundary.
- Do not swallow exceptions. Convert transport/storage failures at their
  boundary and expose stable application errors.
- Check `BuildContext.mounted` after asynchronous gaps before using context.
- Keep widgets focused on rendering and interaction. Put reusable state and
  dependencies in Riverpod providers; do not create service locators or global
  mutable state.
- Reuse app theme tokens and `core/widgets` before introducing local styling or
  duplicate controls.

## Data, security, and observability

- Access HTTP through configured Dio clients and repository abstractions.
- Never log tokens, credentials, authorization headers, personal data, or full
  request/response bodies containing sensitive values.
- Use `AppLogger` and `ErrorReporter`, not third-party SDKs from feature code.
  Third-party observability belongs behind those interfaces.
- Store secrets only through `SecureStorage`. Use key-value storage only for
  non-sensitive preferences.
- Do not commit production secrets, signing credentials, or local production
  configuration.

## Localization and generated code

- User-visible text must come from Slang translation files unless it is a
  platform-owned value or a non-user-facing diagnostic.
- Update every supported locale when adding a translation key.
- Run `make gen` after changing translation sources. Generated output is
  deterministic because Slang timestamps are disabled.

## Testing

- Unit-test domain rules, adapters, parsers, repositories, and providers.
- Widget-test meaningful UI states and user interactions.
- Add integration tests for critical workflows that cross multiple boundaries.
- Every bug fix needs a regression test when the behavior can be reproduced in
  an automated test.
- Tests must be deterministic and must not depend on public networks, real
  credentials, wall-clock timing, or execution order.

## Change discipline

- Read the surrounding code before editing and follow established patterns.
- Keep changes scoped to the requested behavior. Do not mix opportunistic
  refactors with feature work.
- Do not add a dependency when the SDK or an existing package already provides
  a clear solution. New dependencies need a concrete owner and abstraction
  boundary.
- Preserve backward compatibility unless the task explicitly changes a public
  contract. Document intentional migrations.
- Never weaken a checker, lint, or test solely to accept new code. Fix the code
  or make an explicit architectural decision and document it.

## Commands

```sh
make check              # non-mutating source checks used by CI
make fix                # apply Dart fixes, format, and regenerate translations
make architecture-check # AST dependency and platform boundaries
make generated-check    # verify translations without changing the worktree
make test               # unit and widget tests
make check TEST_ARGS=--coverage
```

See [flavors.md](flavors.md), [release.md](release.md), and
[template-usage.md](template-usage.md) for operational workflows.
