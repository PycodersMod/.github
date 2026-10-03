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

## Future repository bootstrap sequence

For each new repository, complete these steps in order:

1. Create the repository in the PycodersMod organization.
2. Initialize its default branch as `main`.
3. Set a repository-local Git identity using `ZYQ-2020` and that account's GitHub-provided noreply address; do not change the global Git identity.
4. Add a root `CODEOWNERS` file assigning ownership to `@ZYQ-2020`.
5. For a Mod repository, place each buildable project under `<loader>/<compatibility-line>/`; keep shared repository metadata at the root. Use the exact Minecraft version directory where the project currently targets a single version, as described in `MOD_REPOSITORY_LAYOUT.md`.
6. Run the public-hygiene scan and resolve all findings before publication.
7. Push the initial repository content to `main`.
8. Apply the repository governance rulesets with `scripts/Apply-PycodersModGovernance.ps1 -Repo <name>`.
9. Audit the repository rulesets and active rules on `main` with `scripts/Apply-PycodersModGovernance.ps1 -Audit`.
10. Mark the repository ready for normal development only after the audit passes.

Add every new repository to the script's explicit repository allowlist. Test governance-script changes against `.github` as the canary before applying them to other repositories.

## Temporary clone and sparse checkout

For a Mod repository, a minimal checkout can select only its project tree:

```powershell
git clone --filter=blob:none --sparse https://github.com/PycodersMod/SharecodeChest.git <TEMP_DIR>/sharecodechest-sparse
git -C <TEMP_DIR>/sharecodechest-sparse sparse-checkout set forge/1.20.1
```

The selected loader/version directory is independently materialized in the working tree. Remove only the temporary clone after confirming no process uses it and no unique evidence is stored there.
