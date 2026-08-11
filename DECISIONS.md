# Design Decisions

## Two separate jobs: diff-scan vs. full-history scan

The workflow only scans the diff of each Pull Request, not the full
repo history, on every run.

Why: scanning the entire history on every PR means an old, already-known
secret (one nobody got around to rotating) fails every future PR, even
ones that don't touch it. Teams learn to ignore a check that "always
fails," which defeats the purpose. A diff-scan keeps the check fast,
relevant, and tied to the person who can actually act on it, right when
they're still in context.

A full-history audit is a separate concern — it belongs in a scheduled
job (e.g. weekly), not in the pull request hot path. Not included in
this version of the kit yet.

## fetch-depth: 0, not a shallow clone

`actions/checkout@v4` defaults to `fetch-depth: 1` (only the latest
commit). Gitleaks needs to diff the PR's commits against their base to
know what's new, so it needs more than one commit available locally.
`fetch-depth: 0` (full history) is the simple way to guarantee that.

A more surgical option exists: fetching only the PR's base and head
SHAs directly, using `github.event.pull_request.base.sha`. That's
faster on large repos, but adds complexity. Skipped for now — this kit
targets small teams with small repos, where `fetch-depth: 0` costs
seconds, not minutes. Worth revisiting if a full-history job or a
larger target repo makes the cost real.

## Don't test with AKIAIOSFODNN7EXAMPLE

`AKIAIOSFODNN7EXAMPLE` is AWS's own documentation example for an access
key format. It shows up hardcoded in publicly shared gitleaks allowlists
as a known false positive, precisely because it's so common in docs and
tutorials. Testing with it can produce a false "all clear" — not because
detection failed, but because the value itself is on an ignore list
somewhere. Use a fake key with valid format but a unique, random value
instead.

## Least-privilege secret scoping

`GITHUB_TOKEN` is declared inside the gitleaks step's `env:`, not at the
job level. It's only needed there. Scoping secrets to the step that uses
them, rather than the whole job, limits what each step can see —
consistent with the kit's "secure by default" premise.
