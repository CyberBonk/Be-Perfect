# Internal development history

This folder contains public historical context that is useful to developers but
should not compete with the recruiter-facing project overview. “Internal” here
means low-priority documentation, not private access: everything committed to a
public GitHub repository is public.

## Provenance

The first concept and implementation brief were created in Codex Plan mode and
were used to produce an intentionally early prototype. Later iterations were
substantially developed, debugged, and tested with Codex. Earlier bounded
OpenCode delegation was also used as an auxiliary review/build aid; it is not a
runtime dependency and is not being invoked by this cleanup.

The files under `prompts/` are historical development artifacts, not required
inputs for running the application.

## Redaction convention

When a historical file contains sensitive material, replace the value in place
so the surrounding instruction remains understandable:

```text
Firebase Key = <Hidden key placed here, for security purposes>
```

Use descriptive placeholders for service credentials, private keys, passwords,
bearer tokens, private endpoints, personal data, signing secrets, and similar
values. Public client configuration and package identifiers may remain when they
are necessary to explain or run the project, but they are not treated as proof
that a backend is safe to reuse.

The prompt files were scanned during this cleanup. No literal service-account
credential, private-key block, password, or bearer token was found in the main
implementation prompt. Review again before publishing any future prompt.

## Contents

- `prompts/` — sanitized implementation and QA handoff history.
- `IMPLEMENTATION_STATUS.md` — implementation status and known limitations.
- `HANDOFF.md` — project handoff context.
