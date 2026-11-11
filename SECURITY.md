# Security and privacy reporting

Minutide activity records can reveal someone's routine. When location logging is enabled, records and CSV exports can include precise coordinates. Avoid sharing those records when diagnosing a problem.

## Report a vulnerability privately

Do not post exploit details, private records, or an attack recipe in a public issue. Use **Security → Report a vulnerability** in [elaren-studio/minutide](https://github.com/elaren-studio/minutide/security). GitHub private vulnerability reporting was enabled and verified on 2026-11-11. If that flow is unavailable, wait for a private contact published by the maintainers; do not send sensitive details through a public issue or discussion.

No dedicated security email is published. Do not infer a personal contact address from the original author's website or from upstream app links. No support or response-time commitment is made.

When reporting, include the affected revision, iOS and device model, a concise impact description, reproduction steps, and whether the report depends on location permission, Shortcuts, device signing, or a CSV destination. Redact real activity data, coordinates, Apple IDs, tokens, and provisioning files.

## Scope and response

Reports should cover this fork's app code, project configuration, and dependencies as used by this repository. The original archived upstream and Apple's operating system or services have separate maintainers. The project has not completed an independent security audit; do not treat this document or the source-level privacy summary as an audit result.

The community project is being revived and has no published support or response-time commitment yet. Maintainers should acknowledge receipt privately, coordinate a fix and disclosure date with the reporter, and publish an advisory only after affected users have a practical update path.
