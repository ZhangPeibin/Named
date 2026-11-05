# Agent Instructions

Read and follow [docs/engineering-standards.md](docs/engineering-standards.md)
before changing this repository. It is the canonical policy for architecture,
code quality, testing, security, generated code, and completion criteria.

For the correct way to perform common tasks (add a feature, API client, route,
provider, translation key, or test), use the
[Agent Playbook](docs/agent/agent-playbook.md). Prefer the scaffolder for new
features: `dart run tool/new_feature.dart <name>`.

Before finishing, run `make check` and report any check that could not run. Do
not revert unrelated worktree changes or edit generated Dart files manually.
