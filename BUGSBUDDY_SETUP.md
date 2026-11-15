# BugsBuddy GitHub Actions starter

This is an installable, customer-runner starter, not a GitHub App or a connected
integration. No source, credentials or results are sent to BugsBuddy. Results
appear in GitHub's PR Checks tab, the workflow summary and its evidence artifact.
There are no automatic PR comments, dashboard imports, baseline comparisons or
remote repository changes.

## Install and configure

1. Download the kit from **BugsBuddy → CI starter kit**. Compare its SHA-256
   checksum with the guide, then extract the archive in your repository root:
   `tar -xzf bugsbuddy-github-actions-1.0.0.tar.gz`. Review the workflow, controller
   and Dockerfiles before committing. The archive contains hidden `.github/`
   and `.bugsbuddy/` directories.
2. Add reviewed harness files under `.bugsbuddy/harnesses/`. For Rust, the file
   is appended to `harnessTarget` in a disposable copy of the PR source; use a
   distinct `#[cfg(kani)]` module and a fully-qualified `#[kani::proof]` name.
   An existing copy of that module in the target must be removed to avoid
   duplicate definitions. The guided scursor harness can be copied from
   BugsBuddy's Guided harnesses page. Review its assumptions and bounds yourself.
   For C/C++, supply a small harness with a named C-compatible function and
   assertions; select the source units to link, without an unrelated main.
   Include repository headers using root-relative include paths.
3. Replace `.bugsbuddy/config.json` with your reviewed target configuration,
   using `config.example.json` as a format example, not a working project.
   Keep only targets that actually exist. Declare real properties and
   assumptions, finite unwind bounds (1–64), and verification budgets
   (10–180 seconds). Eight targets is the maximum. An empty selection, unknown
   option, missing harness, zero parsed verified properties, or incomplete run
   fails rather than looking green.
4. Merge the reviewed installation into the default/base branch **first**.
   Then run **Actions → BugsBuddy selected verification → Run workflow** or
   open a subsequent PR. The initial installation PR cannot bootstrap trusted
   tooling that does not yet exist on its base. PR configuration/harness edits
   intentionally do not affect the check until reviewed and merged.
5. Inspect the PR check, its workflow summary, any accurately mapped annotations,
   and the `bugsbuddy-evidence-…` artifact. Keep the check advisory initially by
   not making it a required merge check. Do not add `continue-on-error`: failed
   or incomplete verification must remain visible as a failed check.

## Trust and execution

- The workflow uses ordinary `pull_request`, not privileged
  `pull_request_target`/`workflow_run`, and a read-only `contents` permission.
  Check status is GitHub Actions' native job status; no `checks: write` or
  `pull-requests: write` token is needed.
- PR source is checked out at its **head commit**. Tooling, selected configuration
  and harnesses come from the PR's **base commit**, in a separate checkout.
  Checkout credentials are not persisted. No secrets are passed into containers.
  Protect workflow/tooling/config/harness changes with required maintainer review
  and appropriate CODEOWNERS/branch rules; this starter does not enforce those
  repository policies or authenticate an evidence bundle cryptographically.
- Use disposable **GitHub-hosted Ubuntu 24.04** runners. Do not run public fork
  PRs on persistent self-hosted machines. GitHub may require maintainer approval
  for fork workflows or repository Actions policy may block them.
- Worker images are built locally from the bundled reviewed Dockerfiles. Kani
  is pinned to 0.68.0/nightly-2026-08-21; the CBMC base is pinned by digest.
  Each target records the resulting image ID and available version output.
  Cargo and Kani use the worker's installed nightly even when the checked
  repository has its own rust-toolchain file. Compatibility failures remain
  explicit; the worker does not download a different compiler during analysis.
  Images and dependencies are not implicitly pulled from a BugsBuddy registry.
- Rust dependency preparation runs in a separate network-enabled container with
  no credentials, Docker socket or host caches. Existing lockfiles are preserved.
  If the crate lacks a lockfile, generated resolution is part of the prepared
  tree, not a claim of reproducible preexisting dependencies. Supply a reviewed
  Cargo.lock/vendor tree for stronger reproducibility. Existing Cargo source
  configuration that cannot resolve offline fails explicitly instead of being
  silently replaced. Private dependencies and authenticated submodules are not
  supported by this starter.
- Analysis has no network, a read-only root/source mount, no capabilities,
  a non-root UID, two CPUs, 4 GiB RAM, PID limits and disposable tmpfs. Rust
  builds execute only inside that container. Timed-out/output-limited containers
  are forcibly removed. Networked dependency preparation has a 120-second
  budget; worker builds have a 300-second budget. Verification has each target's
  configured budget, shared with supplementary evidence capture. The whole job
  has a 30-minute limit; its cancellation or hard timeout may prevent artifact
  upload. That is not a successful verification.

## Evidence and interpretation

The artifact contains `report.json`, readable `summary.md`, the exact selected
configuration and reviewed harnesses, image build/dependency/analysis logs,
bounded failure excerpts, tool-reported counterexamples when available and a
`SHA256SUMS` file. It identifies the checked commit, reviewed base commit,
configuration/harness/prepared-tree/output hashes, image IDs, configured
properties, declared assumptions, unwind bounds, budgets and outcome per target.
Raw logs are files, never unescaped workflow commands.

Kani's native result is authoritative. A supplementary run may add a trace but
cannot turn a failed/incomplete primary check into a pass. Missing or ambiguous
evidence stays unavailable. A trace assignment is not invented as a user input.
Unwind failures, timeouts, build failures, unsupported constructs and output
limits are distinguished from candidate failed properties. An annotation is
emitted only for a retained source location that maps to the PR's checked code;
failures in the injected trusted harness may have no PR annotation.

CBMC links the selected C/C++ units and reviewed harness. It checks harness
assertions plus explicit bounds, pointer validity/overflow, signed overflow,
division-by-zero, undefined-shift and unwinding assertions. This is a small
source-unit workflow, not a replacement for arbitrary CMake/embedded build
systems, target models or integration tests. Unsupported builds fail.

Success covers only the selected harnesses, their modeled environments,
declared assumptions and finite bounds. Counts are properties, not unique bugs.
A passing harness does **not** establish that its specification is correct,
non-vacuous or complete. Build definitions and compiler behavior remain part of
the trusted context. Separate Rust and C/C++ targets do **not** prove their FFI
boundary; Kani itself uses CBMC, so these are not independent votes. Evidence is
reviewable but not a certified audit, tool qualification or compliance claim.

Artifacts may contain sensitive source excerpts and values. This workflow
requests 14-day GitHub artifact retention, subject to repository policy. Apply
your own access and deletion policies before using private source. Nothing is
uploaded to the BugsBuddy dashboard in this version.
