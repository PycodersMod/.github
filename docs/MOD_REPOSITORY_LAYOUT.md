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

Use lowercase canonical Loader directory names followed by the exact Minecraft version. The frozen canonical Loader order for documentation and supported-target tables is: Fabric, Forge, NeoForge, Quilt, LiteLoader, Legacy Fabric, Ornithe Loader, Rift, ModLoader, ModLoaderMP, JarMod, Other. Use the corresponding directory spelling in lowercase where applicable (for example, `fabric`, `forge`, `neoforge`, `quilt`). Sort Minecraft versions by release chronology, newest first within a Loader; do not sort version strings lexically. If a repository has multiple targets for the same Loader, use a single Loader label spanning those rows where the table format supports it.

For target classification, label an ecosystem as Fabric when its selected runtime is Fabric Loader, including supported Ploceus and Ornithe ecosystem projects. Use Ornithe Loader only when Ornithe Loader itself is the runtime.

Add a new target without moving root repository metadata. Keep `.gitignore`, build files, wrapper files, resources, and source sets within the target directory unless a file is intentionally shared and documented. Runtime imports must be configured with a workspace runtime root or discovered from an ancestor; do not depend on a fixed relative depth from the build file.

The layout supports sparse checkout of one target directory, for example `git sparse-checkout set forge/1.20.1`.
