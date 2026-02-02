# KCL in Crossplane compositions with kcl-ccm

A CLI tool that scans a KCL package root and generates:

1. **kustomization.yaml** – ConfigMap definitions for each folder (root + subfolders)
2. **runtime-config.yaml** – Crossplane `DeploymentRuntimeConfig` with volume mounts

This lets you mount your KCL files into the `package-runtime` container of a Crossplane KCL function with a single command.

## Crossplane Composition Approaches

Comparison of different ways to author Crossplane Compositions:

| Criterion                     | Patch & Transform                     | Helm Template          | KCL in Composition            |
| ----------------------------- | ------------------------------------- | ---------------------- | ----------------------------- |
| **Loops & conditionals**      | ❌ Limited (Composition patches only) | ✅ Go templating       | ✅ Full KCL                   |
| **Modularity**                | ❌ Monolithic YAML                    | ✅ Helm charts         | ✅ Separate modules/files     |
| **Reusability**               | ❌ Copy-paste                         | ✅ Chart reuse         | ✅ Import across Compositions |
| **Testability**               | ❌ Hard to unit-test                  | ⚠️ Chart tests         | ✅ `kcl run` locally          |
| **Complex logic**             | ❌ Not designed for it                | ⚠️ Template complexity | ✅ KCL language               |
| **No extra functions**        | ✅ Native Crossplane                  | ❌ function-helm       | ❌ function-kcl               |
| **Readability (large specs)** | ⚠️ Verbose patches                    | ⚠️ Template mix        | ✅ Structured files           |
| **Schema validation**         | ✅ XRD-driven                         | ⚠️ Chart values        | ✅ KCL schemas                |
| **GitOps / same repo**        | ✅                                    | ✅                     | ✅                            |

**Summary:** Patch & Transform is ok for simple, static compositions. Helm suits teams with existing charts. KCL Inline works for small, self-contained logic. **KCL + kcl-ccm** shines when you need modular KCL, loops/conditionals, local testing, and everything in one Git repo.

### How to use KCL in Crossplane Compositions?

| Criterion            | kcl-ccm              | KCL Inline             | OCI Registry                  | Git Source                  | Git-Sync Sidecar            |
| -------------------- | -------------------- | ---------------------- | ----------------------------- | --------------------------- | --------------------------- |
| Local development    | ✅                   | ✅                     | ❌ Needs `kcl mod pull`       | ❌ Needs network            | ❌ Needs network            |
| Single repo          | ✅                   | ✅                     | ❌ Separate publish step      | ✅                          | ✅                          |
| Reusability          | ✅                   | ❌ Per-Composition     | ✅ Chart/package reuse        | ✅ From repo                | ✅ From repo                |
| Testability          | ✅ `kcl run` locally | ⚠️ Extract & test      | ⚠️ Chart tests                | ⚠️ Clone first              | ⚠️ Clone first              |
| Readability          | ✅ Structured files  | ❌ Long inline strings | ✅ In package                 | ✅ In repo                  | ✅ In repo                  |
| No credentials       | ✅                   | ✅                     | ❌ Registry login             | ❌ Private repo needs token | ❌ Private repo needs token |
| No extra registry    | ✅                   | ✅                     | ❌ OCI registry required      | ✅                          | ✅                          |
| No sidecar           | ✅                   | ✅                     | ✅                            | ✅                          | ❌ Sidecar container        |
| No CI/CD for KCL     | ✅                   | ✅                     | ❌ `kcl mod push` in pipeline | ✅                          | ✅                          |
| Offline / air-gapped | ✅                   | ✅                     | ❌ Registry access            | ❌ Git access               | ❌ Git access               |

**Summary:** **KCL Inline** is simplest (no mounting, no extra infra) but not modular. **kcl-ccm** adds modularity while keeping the same benefits (single repo, no credentials, no registry, no sidecar). Use OCI or Git source if you prefer external packaging or need automatic updates from Git.

### Requirements

- Bash 4+
- **GNU realpath** (preferred), Python 3, Python 2, or Perl – for relative path computation. GNU realpath is common on Linux; Python 3 is typically pre-installed on macOS.
- Kustomize (for building; optional for generation)

### Installation

```bash
# From repo root (requires sudo for /usr/local/bin)
sudo make install

# Or copy manually – install -m 755 sets executable bit, no chmod needed
sudo cp 01_scripts/kcl-ccm /usr/local/bin/
```

### Usage

```bash
kcl-ccm --manifest-root <path> --output-kustomize <path> [--output-runtime-config <path>] [--namespace <name>] [--kustomization-name <name>] [--dry-run]
```

**Required:**

| Option               | Description                                                                                                                                                            |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--manifest-root`    | Path to KCL package root (contains `kcl.mod`, `schema.k`, etc.)                                                                                                        |
| `--output-kustomize` | Directory where `kustomization.yaml` will be created. Must be the same as `--manifest-root` or a parent directory (Kustomize requires all files to be under this dir). |

**Optional:**

| Option                    | Description                                                                                                           |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `--output-runtime-config` | Directory where `runtime-config.yaml` will be created. Default: `<output-kustomize>/precore` or `<output-kustomize>`. |
| `--namespace`             | Kubernetes namespace for kustomization.yaml (ConfigMaps). runtime-config.yaml is always `crossplane-system`.          |
| `--kustomization-name`    | `metadata.name` in kustomization.yaml (default: `kclconfig`).                                                         |
| `--dry-run`               | Print generated content to stdout without writing files.                                                              |
| `--help`, `-h`            | Show help                                                                                                             |
| `--version`, `-v`         | Show version                                                                                                          |

### Examples

```bash
# Generate kustomization in KCL dir, runtime-config in crossplane/
kcl-ccm --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --output-runtime-config ./02_example/crossplane

# With custom namespace
kcl-ccm --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --output-runtime-config ./02_example/crossplane --namespace my-namespace

# Preview without writing files
kcl-ccm --manifest-root ./02_example/kcl --output-kustomize ./02_example/kcl --dry-run
```

### Naming Convention

ConfigMaps and volumes use Kubernetes-style names (lowercase, hyphens):

- Root: `kcl-root`
- `templates/k8s` → `kcl-templates-k8s`
- `modules/azure` → `kcl-modules-azure`

### Environment Variables

| Variable              | Default                     | Description                                                                           |
| --------------------- | --------------------------- | ------------------------------------------------------------------------------------- |
| `KUSTOMIZATION_NAME`  | `kclconfig`                 | Kustomization metadata name                                                           |
| `RUNTIME_CONFIG_NAME` | `default`                   | DeploymentRuntimeConfig name                                                          |
| `NAMESPACE`           | `crossplane-system`         | Namespace for kustomization/ConfigMaps. runtime-config is always `crossplane-system`. |
| `MOUNT_BASE`          | `/<manifest-root-basename>` | Base mount path in container                                                          |

### Output

- **kustomization.yaml**: Kustomize config with `configMapGenerator` entries for each folder
- **runtime-config.yaml**: Crossplane `DeploymentRuntimeConfig` with `volumeMounts` and `volumes` for the `package-runtime` container

Only files with extensions `.k`, `.mod`, or `.lock` are included in the ConfigMaps. Other files like `kustomization.yaml` or `*.yaml` are excluded. Folders whose names start with `test` (e.g. `test/`, `packages/k8s/test/`) are ignored.

## Example

The `02_example/` directory contains a minimal KCL package and Crossplane configuration. Run:

```bash
make test
```

to generate the Kustomize and runtime config for `02_example/kcl`.

### Development

Run [ShellCheck](https://www.shellcheck.net/) to lint the script:

```bash
shellcheck 01_scripts/kcl-ccm
```

Install ShellCheck: `brew install shellcheck` (macOS) or see [shellcheck.net](https://www.shellcheck.net/).

## License

MIT (or adjust as needed for your project)
