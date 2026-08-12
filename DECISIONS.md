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

## Two tools for dependencies: npm audit vs. Dependabot

They solve different problems and neither replaces the other.

`npm audit` runs inside the `dependency-check.yml` workflow, on every
Pull Request. It's synchronous and blocking: it reads the current
`package-lock.json` in that PR and fails the check if it finds a
`high` or `critical` vulnerability. This is what catches a brand-new
dependency someone just added that already has a known CVE — before
it merges.

Dependabot (`dependabot.yml`) is passive and continuous. It's not a
job in a workflow — it's a GitHub feature that scans your existing
manifest on a schedule (weekly, in this kit) and opens its own PRs
proposing version bumps when a fix is available. It catches the case
`npm audit` can't: a dependency that was fine when it was added, but
got a CVE published against it months later, with nobody touching
that code in the meantime.

Same pattern as `secret-scan`'s diff-scan vs. full-history split: one
tool guards the moment of change, the other guards the passage of
time.

## --audit-level=high, not the default

Without `--audit-level`, `npm audit` fails on any severity, including
`low`. Most real repos carry low/moderate vulnerabilities in
transitive dependencies that aren't urgent and often can't be fixed
immediately. Blocking every PR over these trains people to ignore the
check — same failure mode discussed for full-history secret scanning.
`--audit-level=high` only blocks on `high` and `critical`, the ones
that actually warrant stopping a merge.

## setup-node is required here, not with gitleaks

Gitleaks ships as a standalone binary — the action installs it
directly, with no dependency on the runner having any language
runtime. `npm audit` is a subcommand of the `npm` CLI, which ships
with Node.js. The `ubuntu-latest` runner doesn't have Node installed
by default, so `actions/setup-node@v4` installs the runtime (and with
it, `npm`) before the audit step can run. Skipping this step would
fail with `command not found`.

## Branch protection isn't a workflow — it's repo configuration

Unlike secret-scan and dependency-check, this isn't a `.yml` file the
buyer copies into `.github/workflows/`. It's a setting on the
repository itself (GitHub Rulesets), so it ships as a script
(`scripts/setup-branch-protection.sh`) that applies the configuration
via the GitHub API instead.

## Three rules, not just "require status checks"

Requiring status checks alone doesn't close the gap: it only applies
*inside* a Pull Request. Someone can still push straight to `main`,
skipping the PR — and with it, every check that only runs on
`pull_request`. Three rules together close this:

- **`deletion`** — `main` can't be deleted by accident.
- **`non_fast_forward`** — blocks force-pushes, so history on `main`
  can't be silently rewritten.
- **`pull_request`** — forces every change through a PR in the first
  place. Without this, `required_status_checks` has nothing to attach
  to, since a direct push never triggers a PR-based check.
- **`required_status_checks`** — the checks (`secret-scan`,
  `dependency-check`) actually have to pass before merging.

## required_approving_review_count: 0

Set to zero on purpose. This kit targets teams of 1-5 people; on a
one-person team, requiring your own approval on every PR is
unworkable. Approvals are left as something the buyer can raise
themselves if their team size calls for it — not a default this kit
imposes.

## Check names are not validated against real workflows

The GitHub API doesn't verify that a required status check name
corresponds to a job that actually exists or runs in the repo. It's a
plain string match: whatever name you pass becomes a requirement,
whether or not any workflow reports that context. Passing an
incorrect or misspelled check name creates a rule that can never be
satisfied — every future PR gets blocked waiting on a check that never
runs. The script takes check names as arguments precisely so the buyer
supplies the exact job names from their own workflows, but it's on
them to get those names right; there's no way to validate this
automatically at rule-creation time.