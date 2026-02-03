# Using KCL in Crossplane compositions with kcl-factory

## Crossplane Composition Approaches

Comparison of possible ways to implement a composition in Crossplane:

| Criterion                | Patch & Transform                     | Go Template                  | KCL                                      |
| ------------------------ | ------------------------------------- | ---------------------------- | ---------------------------------------- |
| **Readability**          | ❌ boilerplate code for patches       | ⚠️ Go's text/template engine | ✅ Structured files and clear kcl syntax |
| **Local development**    | ❌ YAML only                          | ⚠️ Needs `helm template`     | ✅ `kcl run` in repo                     |
| **Loops & conditionals** | ❌ Limited (Composition patches only) | ✅ Go templating             | ✅ Full KCL                              |
| **Modularity**           | ❌ Monolithic YAML                    | ✅ Helm charts               | ✅ Separate packages, modules            |
| **Reusability**          | ❌ Copy-paste                         | ✅ Chart reuse               | ✅ Import across Compositions            |
| **Testability**          | ❌ Hard to unit-test                  | ⚠️ Chart tests               | ✅ `kcl run` locally                     |
| **Runs in CI/CD**        | ✅ Plain YAML                         | ⚠️ Helm in pipeline          | ✅ Script + Kustomize                    |

**Summary:** Patch & Transform suits simple, static compositions. Go fits teams with existing charts, but lacks readability. KCL gives full language power but, is modular and easy to develop and reuse—see.

## Problems

Ok, after reading the comparison of the different Crossplane V2 approaches and the decision made that you are going to implement your enterprise-scale Crossplane compositions with KCL, you will likely run into one of these problems:

**❌ KCL Inline** — You embed KCL code as a string directly in the Composition (which is currently used in [public function-kcl examples](https://github.com/crossplane-contrib/function-kcl)). That gives a bad development experience: no syntax highlighting, no modules or imports, and no reusability across compositions. Changing one line means editing large YAML blocks.

**❌ Artifact / OCI package** — You can publish your KCL as an OCI artifact (e.g. to a container registry) and reference it by tag. That requires a third-party registry, versioning and release process, and often credentials in the cluster to pull the image. Not ideal when you want everything in Git and one `kcl run` locally.

**❌ Repo sync (e.g. Git clone in-cluster)** — A controller or init container clones a Git repo into the function’s filesystem. You then need to manage credentials (SSH keys, tokens, or deploy keys) inside the cluster and handle rotation and security. Extra moving parts and no single-command workflow from your repo.

## Technical Solution

**kcl-factory** addresses all of these problems by automating the generation of the following two files:

1. **kustomization.yaml** – ConfigMap definitions for each folder (root + subfolders)
2. **runtime-config.yaml** – Crossplane `DeploymentRuntimeConfig` with volume mounts, that you can use to add to your "function-kcl" function pod to execute KCL code at runtime

✅ **One command, no manual YAML** — Run `kcl-factory` once; it generates `kustomization.yaml` and `runtime-config.yaml` so your KCL package is mounted into the [function-kcl](https://github.com/crossplane-contrib/function-kcl) runtime. No hand-written ConfigMaps or volume specs.
✅ **Boilerplate code generation** — Folder structure (root + subfolders) is scanned automatically; each folder becomes a ConfigMap and the correct mount paths are set. Change your KCL layout, re-run the tool, done.
✅ **Modularity and local dev** — Keep full KCL packages (modules, imports, `kcl.mod`) in your repo. Use `kcl run` locally with the same structure that runs in the cluster. One source of truth, no inline strings.

- **Less composition complexity** — Define KCL modules that create Kubernetes resources; your Composition stays a thin pipeline that just calls the function with a `source` path. The heavy logic lives in reusable KCL, not in YAML patches.

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

To commit generated files back to the repo, add the following step and set `permissions: contents: write` on the job.

## Environment Variables

| Variable              | Default                     | Description                                                                           |
| --------------------- | --------------------------- | ------------------------------------------------------------------------------------- |
| `KUSTOMIZATION_NAME`  | `kclconfig`                 | Kustomization metadata name                                                           |
| `RUNTIME_CONFIG_NAME` | `default`                   | DeploymentRuntimeConfig name                                                          |
| `NAMESPACE`           | `crossplane-system`         | Namespace for kustomization/ConfigMaps. runtime-config is always `crossplane-system`. |
| `MOUNT_BASE`          | `/<manifest-root-basename>` | Base mount path in container                                                          |

---

⭐ **Enjoying kcl-factory?** If this tool helps you ship KCL-based Crossplane compositions with less friction, consider giving the repo a ⭐ — it supports further development and helps others discover it. Thanks!

## License

License: MIT. See [LICENSE](LICENSE).
