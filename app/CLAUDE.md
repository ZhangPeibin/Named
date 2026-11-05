# Claude Instructions

Follow [docs/engineering-standards.md](docs/engineering-standards.md) as the
single source of truth. Run `make check` before completing a code change, never
edit generated Dart files manually, and preserve unrelated worktree changes.

For how to perform common tasks the right way, follow the
[Agent Playbook](docs/agent/agent-playbook.md). Scaffold new features with
`dart run tool/new_feature.dart <name>` instead of hand-writing the layers.
