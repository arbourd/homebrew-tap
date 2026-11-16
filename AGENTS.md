# homebrew-tap

Personal Homebrew tap: formulae in `Formula/`, casks in `Casks/`.

## Layout

- `Formula/*.rb`: generated, one per registry entry. `Casks/*.rb`: hand-written; currently none, so the cask
  jobs are disabled (see Workflows).
- `tap_migrations.json`: renamed or moved formulae/casks (`orca` moved to `stablyai/orca`). Keep entries; they
  redirect existing installs. Don't add a formula or cask with a migrated name back to this tap.
- `tools/formulae/`: the generator. `formulae.yaml` is the registry, `main.go` the template,
  `githubsource.go` / `gosource.go` the release sources, `testdata/*.rb.golden` the expected output.
- `.github/workflows/`: `formulae-update.yml` and `cask-bump.yml` open bump PRs; `formula.yml` and
  `cask.yml` test them; `go-build.yml` tests the generator.
- On PRs, `formula.yml` and `cask.yml` test only the changed `Formula/*.rb` / `Casks/*.rb`. Pushes to main and
  manual runs test everything, as do PRs that change the workflow itself (for `formula.yml`, also `go.*` or
  `tools/formulae/**`).
- Keep `shell: bash` on their `list` steps: the default shell has no `pipefail`, so a failed generator call
  would skip the tests silently. They also diff against `HEAD^1`, so keep the default PR merge checkout with
  `fetch-depth: 2`. A `Formula/*.rb` without a registry entry is intentionally not tested.

## Formulae registry

- Formulae are generated, never hand-edited. Change the registry (`tools/formulae/formulae.yaml`,
  including each `repo` and `platforms`) or the template in `tools/formulae/main.go`, then regenerate with
  `go run ./tools/formulae <name>`. Update `formulae.schema.json` with any `Spec` field change.
- Entries are explicit: `source`, `desc`, `homepage` and `platforms` have no defaults (only `tag_prefix`
  and `release_notes` do). Keep keys in the order `source`, `repo`, `tag_prefix`, `desc`, `homepage`,
  `release_notes`, `conflicts`, `platforms`, `install`, `test`, with a blank line after `repo` (or
  `source`), `platforms`, and `install`.
- Source: `go` uses `source: go` (reads go.dev, no `repo`, so it sets `release_notes` too); every other
  entry uses `source: github`. Release tags must be `<tag_prefix>X.Y.Z` (or `X.Y`); `tag_prefix` defaults to
  `v`, set it to `""` for bare tags (not for `go`).
- `release_notes` is the PR body link and must contain `#{version}`; it defaults to the GitHub release
  for `source: github`.
- `platforms` maps each supported platform suffix to its asset name (`#{version}` allowed); for `go`
  the values are go.dev filenames. Unlisted platforms are unsupported. List them as `darwin-arm64`,
  `darwin-amd64`, `linux-amd64`, `linux-arm64` (a convention; only the schema enum is checked).
- Every release asset needs a GitHub `digest`. A listed platform with a missing asset or digest fails the
  build; drop the platform from `platforms` if upstream stops publishing it.
- The formula's constraints follow from the platform set:
  - no Linux platform: `depends_on :macos`; no macOS platform: `depends_on :linux`. `formula.yml` runs
    `go run ./tools/formulae --matrix`, which tests each formula only on the OSes in its `platforms`.
  - one arch of an OS (e.g. no `darwin-amd64`): `on_macos do depends_on arch: :arm64 end` (`on_linux`,
    `:intel` likewise)

## Adding a formula (GitHub project)

1. Add a `formulae.yaml` entry keyed by formula name, following the registry rules. Required:
   `source: github`, `repo`, `desc`, `homepage`, `platforms`, `install`, `test`; optional: `tag_prefix`,
   `conflicts`, `release_notes`. Copy the closest existing entry (`git-get` for GoReleaser-style assets,
   `trash` for a macOS-only binary, `opengrep` for custom asset names, `awman` for a partial platform set
   with bare binary assets).
2. `go run ./tools/formulae <name> > /tmp/<name>.rb`; if it exits 0 and looks right, move it to
   `Formula/<name>.rb` and commit it. (Redirecting straight into `Formula/` leaves an empty file on
   failure.) The scheduled workflow only opens bump PRs; it never creates the first file. Until the
   project's GoReleaser `brews:` block is removed, its releases still push these files.
3. `go test ./tools/formulae -run 'TestRenderFormula/^<name>$' -update` creates
   `testdata/<name>.rb.golden` (the golden test fails without it). Commit only that file: a bare `-update`
   also rewrites the `go` golden, which depends on go.dev.
4. Test it with Brew (see Checks). Workflows derive from the registry and the changed `Formula/*.rb`; no edits needed.

## Adding a cask

1. Write `Casks/<name>.rb` by hand, modeled on the old orca cask (`git show b01af31:Casks/orca.rb`): `livecheck` with
   `strategy :github_latest` and a `regex(...)` (so livecheck matches `version`), `url :url`, `depends_on macos:`,
   `zap trash:`. Take the initial `version` and each arch's `sha256` from the asset digests (drop the
   `sha256:` prefix): `gh api repos/<owner>/<repo>/releases/latest --jq '.assets[] | [.name, .digest]'`.
   `cask-bump.yml` only updates them afterward.
2. `cask.yml` and `cask-bump.yml` pick the file up by glob. While `Casks/` is empty their jobs are disabled:
   remove `if: false` from each job, and restore `if: needs.list.outputs.casks != '[]'` on `cask.yml`'s `test`.
3. Run `cask.yml`'s steps locally (see Checks for Brew setup):
   `brew style --cask`, `brew audit --cask --strict --online --except livecheck_version`,
   `brew livecheck --cask`, `brew install --cask`, `brew uninstall --cask --zap` (all with
   `arbourd/tap/<name>`). `cask.yml` also checks that each `app` artifact lands in `/Applications`.

## Workflows

- `formulae-update.yml` skips PR creation on `pull_request` events, so editing it only dry-runs it.
  `cask-bump.yml` has no `pull_request` trigger; test edits with `workflow_dispatch` on a branch.
  The PR it opens is based on that branch, so its diff includes your edits.
- Bot PRs are opened with `GITHUB_TOKEN`, so `formula.yml` / `cask.yml` runs on them sit in
  `action_required`. Each bump leg's last step approves them by matching the PR branch name
  (`<name>-<digit>`, `bump-<name>-<digit>`); keep that in sync with each `branch:` in the workflows.
- `cask-bump.yml` uses brew only to check (`livecheck`) and write (`bump-cask-pr --write-only`); it does
  no git. `create-pull-request` pushes, so reruns reuse the branch and PR (brew's own push can't recover
  from an orphan branch). Keep `arbourd/tap/<cask>` fully qualified: homebrew/cask has an unrelated `orca`.
- `setup-homebrew` already links the checkout as the `arbourd/tap` tap. Don't add an `ln -s` step in a
  workflow that opens PRs: it nests a `homebrew-tap` symlink in the checkout and `create-pull-request`
  commits it. Write scratch files to `$RUNNER_TEMP`, not the checkout, for the same reason.
- `cask.yml` needs at least one cask in `Casks/` (its list step runs `ls Casks/*.rb`, which fails when
  none exist). The last cask is gone, so both workflows have `if: false` on every job (`actionlint` flags the
  constant condition; ignore it).
- Renovate (`.github/renovate.json`) pins actions to SHAs with a semver comment and also bumps `go.mod`.
  Minor and patch action bumps wait 7 days; those for `actions/*` then automerge, and everything else is manual.
- Run `actionlint` after changing anything under `.github/workflows/`.
- Validate `.github/renovate.json` after changing it: `npx --yes --package renovate -- renovate-config-validator --strict`.

## Checks

- Generator: `go vet ./... && go test ./... -race && go run ./tools/formulae go` (hits go.dev).
  `go run ./tools/formulae <name>` hits the GitHub API; set `GITHUB_TOKEN` to avoid rate limits.
  `go run ./tools/formulae --matrix` prints what `formula.yml` tests.
- After changing a template, run `go test ./tools/formulae -update`, then review the golden diff.
- Brew: mirror `formula.yml` / `cask.yml`. Symlink the checkout first
  (`ln -s "$PWD" "$(brew --repository)/Library/Taps/arbourd/homebrew-tap"`) and set
  `HOMEBREW_GITHUB_API_TOKEN` for `--online` audits. If the tap is already a real clone, brew edits
  that clone, not the checkout, so `git checkout` it after write-only tests.
- Test one formula: `go run ./tools/formulae <name> > "$(brew --repository)/Library/Taps/arbourd/homebrew-tap/Formula/<name>.rb"`
  (confirm exit 0 and a non-empty file), then `brew test arbourd/tap/<name>` (must be installed), then
  `git checkout` the file in the clone.
- Brew tests set `XDG_CONFIG_HOME` to a nonexistent `testpath/.config`; tools that need it must `mkpath` it in `test`.
  Tools with their own config dir env var (e.g. `AWMAN_CONFIG_HOME`) should point it at `testpath` too.
- Brew tests are sandboxed to `testpath`: writes elsewhere (e.g. the real Trash) fail. Prefer offline
  tests (local git repos over cloning from GitHub).
