# PycodersMod repository governance

This policy applies to repositories maintained by the PycodersMod organization.

## Ownership and review

- `main` is the default integration branch.
- Changes from contributors are submitted through pull requests.
- Pull requests require one approval and a code owner review; stale approvals are dismissed after a new push.
- `@ZYQ-2020` is the code owner and the only account configured to bypass the collaboration ruleset.
- Force pushes and deletion of the default branch are blocked by a separate history-safety ruleset with no bypass actor.
- No broad organization or administrator bypass is added by this policy.

## Local development and publication

Use a repository-local Git identity for new commits: account `ZYQ-2020` and its GitHub-provided noreply address. Do not change global Git identity for project work. Commit messages and published logs must not contain local absolute paths, private information, private email addresses, hostnames, or local proxy settings.

## Applying and auditing rules

Use `scripts/Apply-PycodersModGovernance.ps1 -Repo <name>` to apply policy to one repository, `-All` for the complete organization set, or `-Audit` to inspect repository rulesets and active rules on `main`. The script requires the authenticated CLI identity `ZYQ-2020`, resolves the numeric account ID live, and uses repository-level ruleset APIs. It does not require organization-wide ruleset administration.

New repositories should be added to the script's explicit repository allowlist, receive a root `CODEOWNERS`, and pass `-Audit` after policy application. Test changes against `.github` as the canary before applying to other repositories.

## Temporary clone and sparse checkout

For a Mod repository, a minimal checkout can select only its project tree:

```powershell
git clone --filter=blob:none --sparse https://github.com/PycodersMod/SharecodeChest.git <TEMP_DIR>/sharecodechest-sparse
git -C <TEMP_DIR>/sharecodechest-sparse sparse-checkout set forge/1.20.1
```

The selected loader/version directory is independently materialized in the working tree. Remove only the temporary clone after confirming no process uses it and no unique evidence is stored there.
