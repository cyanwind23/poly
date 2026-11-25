# Changelog

All notable changes to the **Poly Helm Chart** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.1.0] - 2026-11-25

### ✨ Features
- **External Secrets Operator (`external-secrets.io/v1`)**
  - Added [`externalsecret.yaml`](charts/poly/templates/resources/externalsecret.yaml) (`poly.v3.externalSecret`) to manage Secrets declaratively via `ExternalSecret` (`refreshPolicy`: `Periodic` | `CreatedOnce` | `OnChange`, `refreshInterval`, `secretStoreRef`, `target`, `data`, `dataFrom`) with shared defaults under `default.externalSecret`.
  - Added [`secretstore.yaml`](charts/poly/templates/resources/secretstore.yaml) (`poly.v3.secretStore`) supporting both `SecretStore` and `ClusterSecretStore` (`controller`, `retrySettings`, `refreshInterval`, `conditions`, `provider`, templated `annotations`, and `-prefix` naming).
- **Quick Volume Mounts for `configMaps[]` & `secrets[]`**
  - Added `mountPath` quick-mount support symmetric with `pvcs[].mountPath`, including `subPath`, `readOnly` (default `true`), `volumeName`, `defaultMode`, `optional`, and `items`.
  - Added `exists: true` support to cleanly mount pre-existing `ConfigMap` and `Secret` resources (supporting `fullName`, `-prefix` naming, or literal names) without creating manifests.
- **Kubernetes Gateway API & Cilium Support** ([#6](https://github.com/cyanwind23/poly/issues/6))
  - Added [`httproute.yaml`](charts/poly/templates/resources/httproute.yaml) for `HTTPRoute` and `GRPCRoute` (`gateway.networking.k8s.io/v1`) with `extraRoutes`, `quickConfigs.domain` hostname fallback, default `/` match rule, and automatic `backendRefs` port resolution.
  - Added [`cilium.yaml`](charts/poly/templates/resources/cilium.yaml) for `CiliumNetworkPolicy` and `CiliumEnvoyConfig` (`cilium.io/v2`) with automatic `selectorLabels` `endpointSelector` fallback.
- **Flexible Probes Toggle** ([#3](https://github.com/cyanwind23/poly/issues/3))
  - Added global `probes.enabled` and per-probe `enabled` toggles for `livenessProbe`, `readinessProbe`, and `startupProbe`, plus `quickConfigs.healthcheckPath` shorthand without leaking `enabled` into rendered manifests.
- **Job & CronJob Smart Defaults** ([#1](https://github.com/cyanwind23/poly/issues/1))
  - Automatically sets `podLifecycle.restartPolicy: OnFailure` (and converts inherited `Always` to `OnFailure`) for `Job` and `CronJob` workloads.
  - Skips rendering `probes`, `lifecycle`, `Service`, and `Ingress` for `Job`/`CronJob` by default unless explicitly enabled.
- **ArgoCD Image Updater Tag Precedence** ([#4](https://github.com/cyanwind23/poly/issues/4))
  - Added fallback tag parsing from `quickConfigs.registry` (including registries with ports such as `10.0.0.1:5000/app:v1.0.0`) while keeping `image.repository` and `image.tag` at higher precedence.
- **Helm Values Schema Validation** ([#5](https://github.com/cyanwind23/poly/issues/5))
  - Added [`charts/poly/values.schema.json`](charts/poly/values.schema.json) (JSON Schema Draft 7) validating workload enums, numeric bounds, shortcut/object unions, External Secrets Operator resources, Gateway API, and Cilium configs.

### 🔒 Security / Breaking Changes
- **Removed Inline Raw `Secret` Creation**: Removed `charts/poly/templates/resources/secret.yaml` and disallowed `secrets[].data` / `secrets[].stringData` in [`values.schema.json`](charts/poly/values.schema.json) to prevent committing raw secret values in Git. Use `secrets[].externalSecret` (External Secrets Operator) or `secrets[].exists: true` instead.

### 🐛 Bug Fixes
- Fixed [`serviceaccount.yaml`](charts/poly/templates/resources/serviceaccount.yaml) calling `poly.tpl-dict` instead of `poly.v3.tpl-dict` when `serviceAccount.create: true` and `annotations` are set ([#8](https://github.com/cyanwind23/poly/issues/8)).
- Restored `default.podLifecycle: {}` in [`values.yaml`](charts/poly/values.yaml) to prevent unintended `activeDeadlineSeconds: 10` on all pods ([#1](https://github.com/cyanwind23/poly/issues/1)).

### ♻️ Refactoring
- Split `_podtemplate.yaml` into modular partials: [`_podtemplate.yaml`](charts/poly/templates/helpers/_podtemplate.yaml), [`_volumes.yaml`](charts/poly/templates/helpers/_volumes.yaml), [`_container.yaml`](charts/poly/templates/helpers/_container.yaml), and [`_probes.yaml`](charts/poly/templates/helpers/_probes.yaml) ([#7](https://github.com/cyanwind23/poly/issues/7)).
- Streamlined helper templates across `charts/poly/templates/helpers/`: removed unused `poly.v3.probes`, `poly.v3.lifecycleHooks`, and `poly.v3.pod.schedule`; extracted shared `poly.v3.primaryPort` helper; deduplicated `envFrom`, `volumeMounts`, and probe rendering logic; reused `poly.v3.prefixName`.

### 🧪 Testing & Documentation
- Added automated Helm regression and negative schema validation suite in [`tests/run-tests.sh`](tests/run-tests.sh) with 6 positive test cases (`01`–`06`) and 4 negative schema validation fixtures under `tests/invalid-cases/` ([#8](https://github.com/cyanwind23/poly/issues/8)).
- Updated [`README.md`](README.md), [`tests/README.md`](tests/README.md), [`CONTRIBUTING.md`](CONTRIBUTING.md), [`charts/poly/.helmignore`](charts/poly/.helmignore), and added `LICENSE` and `NOTICE` ([#9](https://github.com/cyanwind23/poly/issues/9)).

---

## [3.0.5] - 2025-09-19
- Baseline v3 Helm chart release supporting multi-app `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob`, `Service`, `Ingress`, `PVC`, `HPA`, `ConfigMap`, `ServiceAccount`, `ServiceMonitor`, `Argo Rollouts`, and `HashiCorp Vault`.
