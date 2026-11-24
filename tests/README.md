# 🧪 Poly Helm Template Test Suite

Bộ test case kiểm thử `helm lint`, `helm template`, đối chiếu golden regression output và xác thực negative schema cho Helm Chart `poly`.

## 📁 Cấu trúc thư mục

```text
tests/
├── cases/
│   ├── 01-image-updater-priority/      # Độ ưu tiên image.tag vs quickConfigs.registry
│   ├── 02-job-cronjob-defaults/        # Giá trị mặc định và tài nguyên điều kiện cho Job & CronJob
│   ├── 03-configmap-secret-mounts/     # Quick volume mount cho ConfigMap (create/exists) & Secret (exists/ExternalSecret)
│   ├── 04-probes-toggle/               # Bật/tắt probes toàn cục, từng probe và healthcheckPath shorthand
│   ├── 05-gateway-api-cilium/          # Kubernetes Gateway API (HTTPRoute/GRPCRoute) & Cilium
│   └── 06-core-workloads-advanced/     # env/envFrom, service/extraServices, ingress, HPA, ServiceMonitor, SA, Vault, Rollout
│       ├── values.yaml                 # File values cấu hình test case
│       └── expected.yaml               # Golden output manifest mong đợi
├── invalid-cases/                      # Các fixture values lỗi để kiểm tra values.schema.json
│   ├── forbidden-inline-secret-data.yaml # Cấm khai báo raw Secret data/stringData trong Git
│   ├── invalid-deploy-type.yaml        # deployType không hợp lệ
│   ├── invalid-pull-policy.yaml        # image.pullPolicy không hợp lệ
│   └── invalid-replicas-type.yaml      # replicas sai kiểu dữ liệu (string thay vì integer)
├── run-tests.sh                        # Script chạy test suite tự động
└── README.md
```

## 📋 Danh sách Positive Test Cases

| Case | Mô tả |
| :--- | :--- |
| `01-image-updater-priority` | Kiểm thử độ ưu tiên giữa `image.repository` / `image.tag` và `quickConfigs.registry` (bao gồm registry có port). |
| `02-job-cronjob-defaults` | Kiểm thử `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob` với `restartPolicy: OnFailure` và tắt mặc định `probes`/`service`/`ingress` cho Job/CronJob. |
| `03-configmap-secret-mounts` | Kiểm thử mount nhanh `ConfigMap` (`create` / `exists`) và `Secret` (`exists` / `ExternalSecret` với `data` & `dataFrom`), bao gồm `mountPath`, `subPath`, `items`, `defaultMode`, `optional`, `-prefix` và kết hợp `volumes`/`pvcs`. |
| `04-probes-toggle` | Kiểm thử kế thừa `default.probes`, tắt qua `probes.enabled: false`, tắt từng probe, shorthand `quickConfigs.healthcheckPath`, bật probe cho Job và `probesOverride`. |
| `05-gateway-api-cilium` | Kiểm thử `HTTPRoute` (kèm `extraRoutes`), `GRPCRoute`, `CiliumNetworkPolicy` và `CiliumEnvoyConfig`. |
| `06-core-workloads-advanced` | Kiểm thử `env` (`~cfm`, `~scr`, `~fr`, `~rfr`, plain), `envFrom` (`-prefix` & `secretRef`), `service` (`ports` + `extraServices`), `ingress` (`hosts` + `tls`), `autoscaling` (HPA), `serviceMonitor`, `serviceAccount` (`create` + `annotations`), `vault` (`template.type: annotation`) và `rollout` (blue-green + preview service/ingress). |

## 🚀 Hướng dẫn sử dụng

### 1. Chạy toàn bộ test suite
Khi chạy không có tham số, script sẽ tự động thực hiện:
1. `helm lint charts/poly`
2. Chạy toàn bộ positive regression cases trong `tests/cases/*` và so sánh với `expected.yaml`
3. Nếu tồn tại `charts/poly/values.schema.json` và `tests/invalid-cases/`, chạy tất cả các file `*.yaml` trong `tests/invalid-cases/` và xác nhận `helm template` trả về mã lỗi khác 0 (reject schema thành công).

```bash
./tests/run-tests.sh
```

### 2. Lọc chạy một test case cụ thể
Bạn có thể truyền một phần hoặc toàn bộ tên thư mục case để chạy nhanh case đó (bỏ qua `helm lint` và `invalid-cases`):
```bash
./tests/run-tests.sh 06-core-workloads-advanced
```

### 3. Cập nhật Golden expected output (`--update` / `-u`)
Khi bạn thêm tính năng mới hoặc cố ý thay đổi template và muốn cập nhật `expected.yaml`:
```bash
# Cập nhật toàn bộ cases
./tests/run-tests.sh --update

# Chỉ cập nhật một case cụ thể
./tests/run-tests.sh 06-core-workloads-advanced --update
```

### 4. Negative Schema Tests (`tests/invalid-cases/`)
Thư mục `tests/invalid-cases/` chứa các file values cố tình vi phạm `charts/poly/values.schema.json`. Runner sẽ fail toàn bộ suite nếu bất kỳ file lỗi nào lại render thành công (exit code 0).

### 5. Thêm một test case mới
1. Tạo thư mục mới trong `tests/cases/`, ví dụ: `tests/cases/07-my-feature/`.
2. Tạo file `values.yaml` chứa cấu hình test.
3. Chạy `./tests/run-tests.sh 07-my-feature --update` để tạo `expected.yaml`.
4. Kiểm tra kỹ `expected.yaml` (có thể xác thực YAML bằng `ruby -ryaml -e 'YAML.load_stream(ARGF.read)' < tests/cases/07-my-feature/expected.yaml`).
