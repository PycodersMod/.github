# Mod repository layout

Each Mod repository keeps shared repository metadata at its root and places each buildable project at `<loader>/<minecraft-version>/`.

Examples:

```text
README.md
LICENSE
CODEOWNERS
forge/1.20.1/
fabric/1.21.6/
neoforge/1.21.1/
```

Use lowercase canonical Loader directory names: `forge`, `neoforge`, `fabric`, `quilt`, followed by the exact Minecraft version. When a repository supports multiple targets, list one target per row in its root README's two-column **Supported Targets** table, with a direct link to the official Loader project and the Minecraft version page. Sort Loader names by the canonical order above and Minecraft versions newest first within a Loader.

Add a new target without moving root repository metadata. Keep `.gitignore`, build files, wrapper files, resources, and source sets within the target directory unless a file is intentionally shared and documented. Runtime imports must be configured with a workspace runtime root or discovered from an ancestor; do not depend on a fixed relative depth from the build file.

The layout supports sparse checkout of one target directory, for example `git sparse-checkout set forge/1.20.1`.
