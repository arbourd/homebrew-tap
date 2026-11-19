# AGENTS.md

Personal Homebrew tap: generated formulae in `Formula/`, hand-written casks in `Casks/` (currently none).

- `tap_migrations.json` redirects existing installs of renamed or moved formulae/casks. Keep its entries,
  and keep migrated names out of this tap.
- `tools/formulae/`: the generator. `formulae.yaml` is the registry, `main.go` the template,
  `testdata/*.rb.golden` the expected output.

## Formulae registry

- `Formula/*.rb` is generated output: change the registry or the template, then regenerate with
  `go run ./tools/formulae <name>`. Update `formulae.schema.json` with any `Spec` field change.
- Entries are explicit: only `tag_prefix` and `release_notes` have defaults. Key order: `source`, `repo`,
  `tag_prefix`, `desc`, `homepage`, `release_notes`, `conflicts`, `platforms`, `install`, `test`, with a
  blank line after `repo` (or `source`), `platforms`, and `install`.
- `source: go` reads go.dev (no `repo`, so set `release_notes`); every other entry is `source: github`.
  Release tags are `<tag_prefix>X.Y.Z` (or `X.Y`); `tag_prefix` defaults to `v`, `""` means bare tags
  (never for `go`).
- `release_notes` is the PR body link and contains `#{version}`; for `github` it defaults to the GitHub release.
- `platforms` maps each supported suffix to its asset name (`#{version}` allowed; go.dev filenames for
  `go`). Unlisted platforms are unsupported. Order: `darwin-arm64`, `darwin-amd64`, `linux-amd64`,
  `linux-arm64`.
- Every listed platform needs an asset with a GitHub `digest`, or the build fails; drop the platform when
  upstream stops publishing it.
- The platform set decides the formula's constraints (`formula.yml` runs `go run ./tools/formulae --matrix`
  to test each formula only on its OSes):
  - no Linux platform: `depends_on :macos`; no macOS platform: `depends_on :linux`.
  - one arch of an OS (e.g. no `darwin-amd64`): `on_macos do depends_on arch: :arm64 end` (`on_linux`,
    `:intel` likewise).

## Adding a formula (GitHub project)

1. Add a `formulae.yaml` entry keyed by formula name. Required: `source`, `repo`, `desc`, `homepage`,
   `platforms`, `install`, `test`. Copy the closest entry: `git-get` (GoReleaser-style assets), `trash`
   (macOS-only binary), `opengrep` (custom asset names), `awman` (partial platform set, bare binary assets).
2. `go run ./tools/formulae <name> > /tmp/<name>.rb`; on exit 0 and sane output, move it to
   `Formula/<name>.rb` and commit it (redirecting straight into `Formula/` leaves an empty file on
   failure). Workflows only open bump PRs, never the first file. Until the project's GoReleaser `brews:`
   block is removed, its releases still push these files.
3. `go test ./tools/formulae -run 'TestRenderFormula/^<name>$' -update` creates `testdata/<name>.rb.golden`
   (the golden test needs it). Commit only that file: a bare `-update` also rewrites the `go` golden,
   which depends on go.dev.
4. Test with Brew (see Checks). Workflows derive from the registry and changed `Formula/*.rb`.

## Adding a cask

1. Write `Casks/<name>.rb` by hand, modeled on the old orca cask (`git show b01af31:Casks/orca.rb`):
   `livecheck` with `strategy :github_latest` and a `regex(...)` matching `version`, `url :url`,
   `depends_on macos:`, `zap trash:`. Take the initial `version` and each arch's `sha256` (drop the
   `sha256:` prefix) from `gh api repos/<owner>/<repo>/releases/latest --jq '.assets[] | [.name, .digest]'`;
   `cask-bump.yml` updates them afterward.
2. Re-enable the cask jobs (see Workflows).
3. Run `cask.yml`'s steps locally (Brew setup in Checks), all with `arbourd/tap/<name>`:
   `brew style --cask`, `brew audit --cask --strict --online --except livecheck_version`,
   `brew livecheck --cask`, `brew install --cask`, `brew uninstall --cask --zap`. `cask.yml` also checks
   that each `app` artifact lands in `/Applications`.

## Workflows

- `formulae-update.yml` and `cask-bump.yml` open bump PRs; `formula.yml` and `cask.yml` test them;
  `go-build.yml` tests the generator.
- On PRs, `formula.yml` and `cask.yml` test only the changed `Formula/*.rb` / `Casks/*.rb`. Pushes to main,
  manual runs, and PRs that change the workflow itself (for `formula.yml`, also `go.*` or
  `tools/formulae/**`) test everything. A `Formula/*.rb` without a registry entry is intentionally untested.
- Their `list` steps keep `shell: bash` (the default shell lacks `pipefail`, so a failed generator call
  would skip the tests silently) and diff against `HEAD^1`, which needs the default PR merge checkout with
  `fetch-depth: 2`.
- `formulae-update.yml` skips PR creation on `pull_request` events, so editing it only dry-runs it.
  `cask-bump.yml` has no `pull_request` trigger: test edits with `workflow_dispatch` on a branch; the PR it
  opens is based on that branch, so its diff includes your edits.
- Bot PRs come from `GITHUB_TOKEN`, so their `formula.yml` / `cask.yml` runs sit in `action_required`. Each
  bump leg's last step approves them by PR branch name (`<name>-<digit>`, `bump-<name>-<digit>`); keep it in
  sync with each `branch:` in the workflows.
- `cask-bump.yml` uses brew only to check (`livecheck`) and write (`bump-cask-pr --write-only`), and does no
  git: `create-pull-request` pushes, so reruns reuse the branch and PR (brew's own push can't recover from
  an orphan branch). Keep `arbourd/tap/<cask>` fully qualified: homebrew/cask has an unrelated `orca`.
- `setup-homebrew` already links the checkout as the `arbourd/tap` tap; an extra `ln -s` step in a PR-opening
  workflow nests a `homebrew-tap` symlink in the checkout, which `create-pull-request` commits. Write
  scratch files to `$RUNNER_TEMP` for the same reason.
- Cask jobs are disabled while `Casks/` is empty: `cask.yml`'s list step runs `ls Casks/*.rb`, which fails
  with no casks, so every job in both cask workflows has `if: false` (`actionlint` flags the constant
  condition; ignore it). With the first cask, remove `if: false` from each job and restore
  `if: needs.list.outputs.casks != '[]'` on `cask.yml`'s `test`.
- Renovate (`.github/renovate.json`) pins actions to SHAs with a semver comment and bumps `go.mod`. Minor and
  patch action bumps wait 7 days; those for `actions/*` then automerge, the rest are manual.
- After changing `.github/workflows/`, run `actionlint`. After changing `.github/renovate.json`, run
  `npx --yes --package renovate -- renovate-config-validator --strict`.

## Checks

- Generator: `go vet ./... && go test ./... -race && go run ./tools/formulae go` (hits go.dev).
  `go run ./tools/formulae <name>` hits the GitHub API; set `GITHUB_TOKEN` to avoid rate limits.
- After changing a template, run `go test ./tools/formulae -update` and review the golden diff.
- Brew: mirror `formula.yml` / `cask.yml`. Symlink the checkout first
  (`ln -s "$PWD" "$(brew --repository)/Library/Taps/arbourd/homebrew-tap"`) and set
  `HOMEBREW_GITHUB_API_TOKEN` for `--online` audits. If the tap is already a real clone, brew edits that
  clone, so `git checkout` it after write-only tests.
- Test one formula: `go run ./tools/formulae <name> > "$(brew --repository)/Library/Taps/arbourd/homebrew-tap/Formula/<name>.rb"`
  (confirm exit 0 and a non-empty file), `brew test arbourd/tap/<name>` (must be installed), then
  `git checkout` the file in the clone.
- Brew tests run sandboxed to `testpath`, with `XDG_CONFIG_HOME` set to a nonexistent `testpath/.config`:
  `mkpath` it in `test` if the tool needs it, point tools with their own config dir variable (e.g.
  `AWMAN_CONFIG_HOME`) at `testpath`, and prefer offline tests (local git repos over cloning from GitHub).
  Writes elsewhere (e.g. the real Trash) fail.
