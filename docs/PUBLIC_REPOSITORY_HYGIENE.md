# Public repository hygiene

PycodersMod repositories are public-safe by default. Before committing, opening a pull request, or uploading an artifact, check the staged/current tree and generated logs for:

- machine-specific absolute paths and usernames;
- private personal information, hostnames, or private email addresses;
- local proxy configuration, tokens, credentials, and authentication data;
- unredacted build/runtime logs and machine-local configuration.

Use generic placeholders such as `<WORKSPACE_ROOT>`, `<TEMP_DIR>`, and `<REPOSITORY_ROOT>` in documentation. Runtime-local evidence may retain original paths only while it remains local and unpublished. If a historical commit contains identifying metadata, record the finding and obtain explicit authorization before any history rewrite; do not force-push as part of routine cleanup.

Run `scripts/Test-PublicRepositoryHygiene.ps1 -WorkspaceRoot <WORKSPACE_ROOT>` for a current-tree scan. The scanner reports repository-relative paths and finding categories only; it must not print matched values. Review findings manually to distinguish examples and public test fixtures from actual local data.
