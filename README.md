# Using KCL in Crossplane compositions with kcl-factory

A CLI tool that scans a KCL package root and generates:

1. **kustomization.yaml** – ConfigMap definitions for each folder (root + subfolders)
2. **runtime-config.yaml** – Crossplane `DeploymentRuntimeConfig` with volume mounts

✅ This lets you mount your KCL files into the runtime container of a Crossplane KCL function "function-kcl" with a single command.

## Crossplane Composition Approaches

Comparison possible ways to implement a compositon in crossplane:

| Criterion                | Patch & Transform                     | Go Template                  | KCL Inline                   | kcl-factory                   |
| ------------------------ | ------------------------------------- | ---------------------------- | ---------------------------- | ----------------------------- |
| **Readability**          | ❌ boilerplate code for patches       | ⚠️ Go's text/template engine | ❌ Long inline strings       | ✅ Structured files           |
| **Local development**    | ❌ YAML only                          | ⚠️ Needs `helm template`     | ✅ Inline in Composition     | ✅ `kcl run` in repo          |
| **Loops & conditionals** | ❌ Limited (Composition patches only) | ✅ Go templating             | ✅ Full KCL                  | ✅ Full KCL                   |
| **Modularity**           | ❌ Monolithic YAML                    | ✅ Helm charts               | ❌ Per-Composition, no split | ✅ Separate packages, modules |
| **Reusability**          | ❌ Copy-paste                         | ✅ Chart reuse               | ❌ Per-Composition           | ✅ Import across Compositions |
| **Testability**          | ❌ Hard to unit-test                  | ⚠️ Chart tests               | ⚠️ Extract & test            | ✅ `kcl run` locally          |
| **Runs in CI/CD**        | ✅ Plain YAML                         | ⚠️ Helm in pipeline          | ✅ No extra steps            | ✅ Script + Kustomize         |

**Summary:** Patch & Transform suits simple, static compositions. Go fits teams with existing charts. KCL Inline is minimal (no mounting) but not modular and hard to further develop. **kcl-factory** adds modularity with local development, full KCL Package modularity and structured files in one repo.

### Requirements

- Bash 4+
- **GNU realpath** (preferred), Python 3, Python 2, or Perl – for relative path computation. GNU realpath is common on Linux; Python 3 is typically pre-installed on macOS.

### Installation

```bash
# From repo root (requires sudo for /usr/local/bin)
sudo make install

# Or copy manually – install -m 755 sets executable bit, no chmod needed
sudo cp 01_scripts/kcl-factory /usr/local/bin/
```

## Usage

### Command

```bash
kcl-factory --manifest-root <path> --output-kustomize <path> --output-runtime-config <path> [--namespace <name>] [--kustomization-name <name>] [--dry-run]
```

#### Required:

| Option                    | Description                                                                                                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--manifest-root`         | Path to KCL package root (contains `kcl.mod`, `schema.k`, etc.)                                                                                                        |
| `--output-kustomize`      | Directory where `kustomization.yaml` will be created. Must be the same as `--manifest-root` or a parent directory (Kustomize requires all files to be under this dir). |
| `--output-runtime-config` | Directory where `runtime-config.yaml` will be created.                                                                                                                 |

#### Optional:

| Option                 | Description                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------------ |
| `--namespace`          | Kubernetes namespace for kustomization.yaml (ConfigMaps). runtime-config.yaml is always `crossplane-system`. |
| `--kustomization-name` | `metadata.name` in kustomization.yaml (default: `kclconfig`).                                                |
| `--dry-run`            | Print generated content to stdout without writing files.                                                     |
| `--help`, `-h`         | Show help                                                                                                    |
| `--version`, `-v`      | Show version                                                                                                 |

#### Output:

- **kustomization.yaml**: Kustomize config with `configMapGenerator` entries for each folder
- **runtime-config.yaml**: Crossplane `DeploymentRuntimeConfig` with `volumeMounts` and `volumes` for the `package-runtime` container

ℹ️ Only files with extensions `.k`, `.mod`, or `.lock` are included in the ConfigMaps.
ℹ️ Other files like `*.yaml` are excluded. Folders whose names start with `test` (e.g. `test/`, `packages/k8s/test/`) are ignored.

### Example

The `02_example/` directory contains a minimal KCL package and Crossplane configuration. Run:

```bash
make test
```

to generate the Kustomize and runtime config for `02_example/kcl`.

### Execution

```bash
# Generate kustomization in KCL dir, runtime-config in crossplane/
kcl-factory --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --output-runtime-config ./02_example/crossplane

# With custom namespace
kcl-factory --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --output-runtime-config ./02_example/crossplane --namespace my-namespace

# Preview without writing files
kcl-factory --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --output-runtime-config ./02_example/crossplane --dry-run
```

### CI/CD (GitHub Actions)

kcl-factory can be run inside a CI/CD pipeline without extra registries or credentials. Example: generate Kustomize and runtime config on every push

```yaml
name: kcl-factory

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install kcl-factory
        run: |
          sudo cp 01_scripts/kcl-factory /usr/local/bin/
          sudo chmod +x /usr/local/bin/kcl-factory

      - name: Generate Kustomize and runtime config
        run: |
          kcl-factory --manifest-root ./02_example/kcl \
            --output-kustomize ./02_example/kcl \
            --output-runtime-config ./02_example/crossplane
```

To commit generated files back to the repo, add the following step and set `permissions: contents: write` on the job

## Environment Variables

| Variable              | Default                     | Description                                                                           |
| --------------------- | --------------------------- | ------------------------------------------------------------------------------------- |
| `KUSTOMIZATION_NAME`  | `kclconfig`                 | Kustomization metadata name                                                           |
| `RUNTIME_CONFIG_NAME` | `default`                   | DeploymentRuntimeConfig name                                                          |
| `NAMESPACE`           | `crossplane-system`         | Namespace for kustomization/ConfigMaps. runtime-config is always `crossplane-system`. |
| `MOUNT_BASE`          | `/<manifest-root-basename>` | Base mount path in container                                                          |

## License

MIT (or adjust as needed for your project)
