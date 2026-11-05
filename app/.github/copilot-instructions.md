# Copilot Instructions

Follow `docs/engineering-standards.md` as the repository's canonical policy.
Changes must respect its architecture boundaries and pass `make check`. Do not
edit generated Dart files manually or introduce unsupported platforms.

See `docs/agent/agent-playbook.md` for the correct shape of common tasks. Scaffold
new features with `dart run tool/new_feature.dart <name>`.
