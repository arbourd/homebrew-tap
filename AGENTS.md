# homebrew-tap

Personal Homebrew tap: formulae in `Formula/`, casks in `Casks/`.

## Layout

- `Formula/*.rb`: generated, one per registry entry. `Casks/*.rb`: hand-written.
- `tools/formulae/`: the generator. `formulae.yaml` is the registry, `main.go` the template,
  `githubsource.go` / `gosource.go` the release sources, `testdata/*.rb.golden` the expected output.
- `.github/workflows/`: `formulae-update.yml` and `cask-bump.yml` open bump PRs; `formula.yml` and
  `cask.yml` test them; `go-build.yml` tests the generator.

## Gotchas

- Formulae are generated, never hand-edited. Change the registry (`tools/formulae/formulae.yaml`,
  including each `repo`) or the template in `tools/formulae/main.go`, then regenerate with `go run ./tools/formulae <name>`.
  Update `formulae.schema.json` with any `Spec` field change.
- `go` uses `source: go` (reads go.dev, no `repo`, so it sets `homepage` and `release_notes`); every
  other entry reads GitHub releases. `release_notes` is the PR body link and must contain `#{version}`;
  `homepage` and `release_notes` default to the GitHub repo and its release.
- `formula.yml` skips Linux for a formula only if it has a bare `depends_on :macos` line.
  A versioned form (`macos: :ventura`) is still tested on Linux.
- The update workflows skip PR creation on `pull_request` events, so editing one only dry-runs it.
- Bot PRs are opened with `GITHUB_TOKEN`, so `formula.yml` / `cask.yml` runs on them sit in
  `action_required`. Each bump workflow's last step approves them by matching the PR branch name
  (`<name>-<digit>`, `bump-`); keep that in sync with each `branch:` in the workflows.
- Keep `--full-name` on `brew bump --cask` in `cask-bump.yml`: homebrew/cask has an unrelated `orca`,
  and a bare name makes `bump-cask-pr` target that one.
- `cask.yml` needs at least one cask in `Casks/` (an empty matrix errors). If the last cask is
  removed, disable both jobs with `if: false`.
- Pin third-party actions to release tags, not SHAs. Renovate bumps them (`.github/renovate.json`).

## Adding a formula (GitHub project)

1. Add a `formulae.yaml` entry keyed by formula name: `repo`, `desc`, `install`, `test`; optionally
   `mac_only`, `conflicts`, `urls`. Copy the closest existing entry (`trash` for a macOS-only binary,
   `opengrep` for custom asset names).
2. Every release asset needs a GitHub `digest`. Assets default to GoReleaser-style
   `<name>-v<ver>-<os>-<arch>.tar.gz`; a `urls` map (platform suffix like `darwin-arm64` -> full URL with
   `#{version}`, every non-skipped platform required) overrides that. Until the project's GoReleaser
   `brews:` block is removed, its releases still push these files.
3. `go run ./tools/formulae <name> > /tmp/<name>.rb`; if it exits 0 and looks right, move it to
   `Formula/<name>.rb` and commit it. (Redirecting straight into `Formula/` leaves an empty file on
   failure.) The scheduled workflow only opens bump PRs; it never creates the first file.
4. `go test ./tools/formulae -run 'TestRenderFormula/^<name>$' -update` creates
   `testdata/<name>.rb.golden` (the golden test fails without it). Commit only that file: a bare `-update`
   also rewrites the `go` golden, which depends on go.dev.
5. Test it with Brew (see Checks). Workflows derive from the registry and `Formula/*.rb`; no edits needed.

## Adding a cask

1. Write `Casks/<name>.rb` by hand, modeled on `Casks/orca.rb`: `livecheck` with
   `strategy :github_latest` and a `regex(...)` (so livecheck matches `version`), `url :url`, `depends_on macos:`,
   `zap trash:`. Take the initial `version` and each arch's `sha256` from the asset digests (drop the
   `sha256:` prefix): `gh api repos/<owner>/<repo>/releases/latest --jq '.assets[] | [.name, .digest]'`.
   `brew bump` only updates them afterward.
2. Add the cask to the `brew bump` step in `cask-bump.yml` (names are hardcoded; e.g.
   `... arbourd/tap/orca arbourd/tap/<name>`). Keep its flags. The approval step already matches any
   `bump-*` branch.
3. `cask.yml` picks the file up by glob. Run its steps locally (symlink the tap, see Checks):
   `brew style --cask`, `brew audit --cask --strict --online --except livecheck_version`,
   `brew livecheck --cask`, `brew install --cask`, `brew uninstall --cask --zap` (all with
   `arbourd/tap/<name>`). `cask.yml` also checks that each `app` artifact lands in `/Applications`.

## Checks

- Generator: `go vet ./... && go test ./... -race && go run ./tools/formulae go` (hits go.dev).
  `go run ./tools/formulae <name>` hits the GitHub API; set `GITHUB_TOKEN` to avoid rate limits.
- After changing a template, run `go test ./tools/formulae -update`, then review the golden diff.
- Brew tests set `XDG_CONFIG_HOME` to a nonexistent `testpath/.config`; tools that need it must `mkpath` it in `test`.
- Brew tests are sandboxed to `testpath`: writes elsewhere (e.g. the real Trash) fail. Prefer offline
  tests (local git repos over cloning from GitHub).
- Brew: mirror `formula.yml` / `cask.yml`. Symlink the checkout first
  (`ln -s "$PWD" "$(brew --repository)/Library/Taps/arbourd/homebrew-tap"`) and set
  `HOMEBREW_GITHUB_API_TOKEN` for `--online` audits. If the tap is already a real clone, brew edits
  that clone, not the checkout, so `git checkout` it after write-only tests.
- Test one formula: `go run ./tools/formulae <name> > "$(brew --repository)/Library/Taps/arbourd/homebrew-tap/Formula/<name>.rb"`
  (confirm exit 0 and a non-empty file), then `brew test arbourd/tap/<name>` (must be installed), then
  `git checkout` the file in the clone.
