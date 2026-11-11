# Security and privacy reporting

Minutide activity records can reveal someone's routine. When location logging is enabled, records and CSV exports can include precise coordinates. Avoid sharing those records when diagnosing a problem.

## Report a vulnerability privately

Do not post exploit details, private records, or an attack recipe in a public issue. If private vulnerability reporting is enabled on the community repository, use its **Security → Report a vulnerability** flow. If that flow is not available, use a private contact published by the repository maintainers; do not send sensitive details through a public issue or discussion.

No dedicated security email or verified private-reporting endpoint is published in this checkout. Enabling and verifying a private reporting route is a release-readiness task. Do not infer a contact address from the original author's website or from upstream app links.

When reporting, include the affected revision, iOS and device model, a concise impact description, reproduction steps, and whether the report depends on location permission, Shortcuts, device signing, or a CSV destination. Redact real activity data, coordinates, Apple IDs, tokens, and provisioning files.

## Scope and response

Reports should cover this fork's app code, project configuration, and dependencies as used by this repository. The original archived upstream and Apple's operating system or services have separate maintainers. The project has not completed an independent security audit; do not treat this document or the source-level privacy summary as an audit result.

The community project is being revived and has no published support or response-time commitment yet. Maintainers should acknowledge receipt privately, coordinate a fix and disclosure date with the reporter, and publish an advisory only after affected users have a practical update path.
