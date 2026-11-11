# homebrew-tap

Personal Homebrew tap: formulae in `Formula/`, casks in `Casks/`.

## Layout

- `Formula/*.rb`: generated, one per registry entry. `Casks/*.rb`: hand-written.
- `tools/formulae/`: the generator. `formulae.yaml` is the registry, `main.go` the template,
  `githubsource.go` / `gosource.go` the release sources, `testdata/*.rb.golden` the expected output.
- `.github/workflows/`: `formulae-update.yml` and `cask-bump.yml` open bump PRs; `formula.yml` and
  `cask.yml` test them; `go-build.yml` tests the generator.

## Formulae registry

- Formulae are generated, never hand-edited. Change the registry (`tools/formulae/formulae.yaml`,
  including each `repo` and `platforms`) or the template in `tools/formulae/main.go`, then regenerate with
  `go run ./tools/formulae <name>`. Update `formulae.schema.json` with any `Spec` field change.
- Entries are explicit: `source`, `desc`, `homepage` and `platforms` have no defaults. Keep keys in the
  order `source`, `repo`, `desc`, `homepage`, `release_notes`, `conflicts`, `platforms`, `install`, `test`,
  with a blank line after `repo` (or `source`), `platforms`, and `install`.
- Source: `go` uses `source: go` (reads go.dev, no `repo` or `platforms`, so it sets `release_notes` too); every other
  entry uses `source: github`. The generator only supports `vX.Y.Z` (or `vX.Y`) release tags: the asset
  URL hard-codes the `v`.
- `release_notes` is the PR body link and must contain `#{version}`; it defaults to the GitHub release
  for `source: github`.
- `platforms` maps each supported platform suffix to its asset name (`#{version}` allowed).
  Unlisted platforms are unsupported. List them as `darwin-arm64`,
  `darwin-amd64`, `linux-amd64`, `linux-arm64` (a convention; only the schema enum is checked).
- Every release asset needs a GitHub `digest`. A listed platform with a missing asset or digest fails the
  build; drop the platform from `platforms` if upstream stops publishing it.
- The formula's constraints follow from the platform set:
  - no Linux platform: `depends_on :macos`; no macOS platform: `depends_on :linux`. `formula.yml` then
    tests only the other OS, but only for these bare lines; a versioned form (`macos: :ventura`) is still
    tested on Linux.
  - one arch of an OS (e.g. no `darwin-amd64`): `on_macos do depends_on arch: :arm64 end` (`on_linux`,
    `:intel` likewise)

## Adding a formula (GitHub project)

1. Add a `formulae.yaml` entry keyed by formula name, following the registry rules. Required:
   `source: github`, `repo`, `desc`, `homepage`, `platforms`, `install`, `test`; optional: `conflicts`,
   `release_notes`. Copy the closest existing entry (`git-get` for GoReleaser-style assets, `trash` for a
   macOS-only binary, `opengrep` for custom asset names).
2. `go run ./tools/formulae <name> > /tmp/<name>.rb`; if it exits 0 and looks right, move it to
   `Formula/<name>.rb` and commit it. (Redirecting straight into `Formula/` leaves an empty file on
   failure.) The scheduled workflow only opens bump PRs; it never creates the first file. Until the
   project's GoReleaser `brews:` block is removed, its releases still push these files.
3. `go test ./tools/formulae -run 'TestRenderFormula/^<name>$' -update` creates
   `testdata/<name>.rb.golden` (the golden test fails without it). Commit only that file: a bare `-update`
   also rewrites the `go` golden, which depends on go.dev.
4. Test it with Brew (see Checks). Workflows derive from the registry and `Formula/*.rb`; no edits needed.

## Adding a cask

1. Write `Casks/<name>.rb` by hand, modeled on `Casks/orca.rb`: `livecheck` with
   `strategy :github_latest` and a `regex(...)` (so livecheck matches `version`), `url :url`, `depends_on macos:`,
   `zap trash:`. Take the initial `version` and each arch's `sha256` from the asset digests (drop the
   `sha256:` prefix): `gh api repos/<owner>/<repo>/releases/latest --jq '.assets[] | [.name, .digest]'`.
   `brew bump` only updates them afterward.
2. Add the cask to the `brew bump` step in `cask-bump.yml` (names are hardcoded; e.g.
   `... arbourd/tap/orca arbourd/tap/<name>`). Keep its flags. The approval step already matches any
   `bump-*` branch.
3. `cask.yml` picks the file up by glob. Run its steps locally (see Checks for Brew setup):
   `brew style --cask`, `brew audit --cask --strict --online --except livecheck_version`,
   `brew livecheck --cask`, `brew install --cask`, `brew uninstall --cask --zap` (all with
   `arbourd/tap/<name>`). `cask.yml` also checks that each `app` artifact lands in `/Applications`.

## Workflows

- The update workflows skip PR creation on `pull_request` events, so editing one only dry-runs it.
- Bot PRs are opened with `GITHUB_TOKEN`, so `formula.yml` / `cask.yml` runs on them sit in
  `action_required`. Each bump workflow's last step approves them by matching the PR branch name
  (`<name>-<digit>`, `bump-`); keep that in sync with each `branch:` in the workflows.
- Keep `--full-name` on `brew bump --cask` in `cask-bump.yml`: homebrew/cask has an unrelated `orca`,
  and a bare name makes `bump-cask-pr` target that one.
- `cask.yml` needs at least one cask in `Casks/` (an empty matrix errors). If the last cask is
  removed, disable both jobs with `if: false`.
- Pin third-party actions to release tags, not SHAs. Renovate bumps them (`.github/renovate.json`).

## Checks

- Generator: `go vet ./... && go test ./... -race && go run ./tools/formulae go` (hits go.dev).
  `go run ./tools/formulae <name>` hits the GitHub API; set `GITHUB_TOKEN` to avoid rate limits.
- After changing a template, run `go test ./tools/formulae -update`, then review the golden diff.
- Brew: mirror `formula.yml` / `cask.yml`. Symlink the checkout first
  (`ln -s "$PWD" "$(brew --repository)/Library/Taps/arbourd/homebrew-tap"`) and set
  `HOMEBREW_GITHUB_API_TOKEN` for `--online` audits. If the tap is already a real clone, brew edits
  that clone, not the checkout, so `git checkout` it after write-only tests.
- Test one formula: `go run ./tools/formulae <name> > "$(brew --repository)/Library/Taps/arbourd/homebrew-tap/Formula/<name>.rb"`
  (confirm exit 0 and a non-empty file), then `brew test arbourd/tap/<name>` (must be installed), then
  `git checkout` the file in the clone.
- Brew tests set `XDG_CONFIG_HOME` to a nonexistent `testpath/.config`; tools that need it must `mkpath` it in `test`.
- Brew tests are sandboxed to `testpath`: writes elsewhere (e.g. the real Trash) fail. Prefer offline
  tests (local git repos over cloning from GitHub).
