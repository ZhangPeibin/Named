# Domain Docs

Domain documentation uses a single-context layout:

- Root `CONTEXT.md` contains the project's domain vocabulary and concepts.
- `docs/adr/` contains architecture decision records that apply across the repository.

Before exploring or changing an area, read `CONTEXT.md` when it exists and the ADRs relevant to that area. Use the glossary's terms in issues, proposals, and tests. If a needed concept is not defined, note the gap rather than inventing project terminology. Surface conflicts with existing ADRs explicitly.

If these documents do not exist yet, proceed without treating their absence as a problem. Create them when domain terms or architectural decisions are actually resolved.
