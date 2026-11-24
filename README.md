# Poly 🚀

```console
 ____        ___
/\  _`\     /\_ \
\ \ \L\ \___\//\ \    __  __
 \ \ ,__/ __`\\ \ \  /\ \/\ \
  \ \ \/\ \L\ \\_\ \_\ \ \_\ \
   \ \_\ \____//\____\\/`____ \
    \/_/\/___/ \/____/ `/___/> \
                          /\___/
                          \/__/
```

**Poly** là một Helm library/subchart mạnh mẽ được thiết kế để đơn giản hóa việc deploy nhiều microservice/ứng dụng (`multi-app`) cùng lúc trên Kubernetes. Thay vì phải sao chép các file templates (Deployment, Service, Ingress, HPA, PVC,...) cho từng ứng dụng, Poly cho phép định nghĩa tất cả cấu hình của nhiều ứng dụng tại một file `values.yaml` duy nhất với cơ chế kế thừa thông minh.

---

## ✨ Các Tính Năng Nổi Bật

- **Kế thừa & Ghi đè cấu hình (Inheritance & Override)**: Định nghĩa các cấu hình chung tại block `default` và ghi đè riêng biệt cho từng ứng dụng.
- **Cú pháp rút gọn thông minh (Smart Shortcuts)**:
  - **Environment Variables**: Tham chiếu ConfigMap/Secret/Metadata chỉ với 1 dòng chuỗi.
  - **Volume & Quick Mount**: Map PV/PVC, ConfigMap và Secret nhanh gọn chỉ với `mountPath` hoặc chuỗi phân tách bằng dấu hai chấm `:`.
  - **Probes**: Bật/tắt toàn cục hoặc từng probe linh hoạt, hỗ trợ shorthand `quickConfigs.healthcheckPath`.
- **Smart Workload Defaults**: Hỗ trợ đầy đủ `Deployment`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob` với cơ chế tự động điều chỉnh `restartPolicy` và các resource phụ trợ cho Job/CronJob.
- **Tích hợp Cloud-Native & GitOps mạnh mẽ**:
  - **ArgoCD Image Updater**: Tách bạch độ ưu tiên `image.tag` > `quickConfigs.registry` giúp ArgoCD Image Updater cập nhật tag dễ dàng.
  - **Kubernetes Gateway API**: Hỗ trợ gốc `HTTPRoute` và `GRPCRoute` (`gateway.networking.k8s.io/v1`).
  - **Cilium**: Hỗ trợ `CiliumNetworkPolicy` và `CiliumEnvoyConfig` (`cilium.io/v2`).
  - **Argo Rollouts**: Hỗ trợ chiến lược Blue-Green kèm Service & Ingress Preview.
  - **External Secrets Operator**: Quản lý Secret qua `ExternalSecret` thay cho việc lưu trữ Secret thô trong Git.
  - **HashiCorp Vault**: Tích hợp Vault Agent Injector tự động.
  - **Prometheus**: Hỗ trợ tạo nhanh `ServiceMonitor` để thu thập metrics.
- **Schema Validation**: Tích hợp `values.schema.json` giúp phát hiện sớm lỗi sai kiểu dữ liệu hoặc giá trị không hợp lệ ngay từ bước `helm lint` / `helm template`.

---

## 📦 Cách Hoạt Động & Cấu trúc Cấu hình

Poly được thiết kế để hoạt động như một **dependency (subchart)** trong Helm chart của bạn.

### Cấu trúc Values
Mọi ứng dụng sẽ được khai báo là một key trực tiếp nằm dưới scope của subchart `poly` trong file `values.yaml` của chart cha (ngoại trừ các key dành riêng là `default`, `apps` và `defaultApp`).
- **`default`**: Chứa toàn bộ cấu hình mặc định (kế thừa bởi tất cả app).
- **`<appName>`**: Block định nghĩa riêng cho từng app. Nếu `enabled: true`, Poly sẽ sinh ra các Kubernetes resources cho app này.

> [!IMPORTANT]
> Các key đại diện cho tên ứng dụng (nằm ngay bên dưới `poly:`) **phải được đặt ở định dạng camelCase** (ví dụ: `apiService`, `backgroundWorker`). Đây là quy chuẩn bắt buộc để Helm nhận diện và khởi tạo các Kubernetes resources tương ứng một cách chính xác.

> [!WARNING]
> Không định nghĩa các app của bạn dưới key `poly.apps.<appName>`. Trong phiên bản v3, key `apps` đã bị loại trừ trong logic render để tránh xung đột cấu hình. Hãy khai báo trực tiếp ở root scope của subchart (ví dụ: `poly.<appName>`).

---

## 🚀 Hướng Dẫn Sử Dụng Nhanh

### Bước 1: Tạo Helm Chart của bạn
Tạo một Helm chart mới và dọn dẹp các template mặc định (vì chúng ta sẽ dùng templates của Poly):

```console
helm create mychart
rm -rf mychart/templates/*
```

### Bước 2: Thêm Poly làm Dependency
Cấu hình file `mychart/Chart.yaml`:

```yaml
apiVersion: v2
name: mychart
description: My microservices stack
type: application
version: 1.0.0
appVersion: "1.0.0"

dependencies:
  - name: poly
    repository: https://github.com/cyanwind23/poly
    version: "3.1.0" # Sử dụng version phù hợp
```

> [!NOTE]
> **Điểm nổi bật ở `v3.1.0`**: Bổ sung độ ưu tiên tag cho ArgoCD Image Updater (`image.tag` > `quickConfigs.registry`), smart defaults cho `Job`/`CronJob`, quick volume mount cho `configMaps[]` & `secrets[]`, cơ chế bật/tắt `probes` linh hoạt, hỗ trợ Kubernetes Gateway API (`HTTPRoute`, `GRPCRoute`) & Cilium (`CiliumNetworkPolicy`, `CiliumEnvoyConfig`), cùng kiểm tra hợp lệ bằng `values.schema.json`.

Sau đó chạy lệnh để cập nhật dependency:

```console
helm dependency update mychart
```

### Bước 3: Định nghĩa cấu hình trong `values.yaml`
Dưới đây là ví dụ minh họa cấu hình deploy 2 ứng dụng: `apiService` và `backgroundWorker` trong file `mychart/values.yaml`:

```yaml
poly:
  # Cấu hình mặc định chung cho toàn bộ app
  default:
    replicas: 1
    image:
      pullPolicy: IfNotPresent
    ports:
      - 80:http:TCP

  # Ứng dụng 1: Web API (Deployment + Service + Ingress)
  apiService:
    enabled: true
    deployType: Deployment
    image:
      repository: myregistry.com/api-service
      tag: "v1.2.0"
    ingress:
      enabled: true
      hosts:
        - host: api.example.com
          paths:
            - /:Prefix

  # Ứng dụng 2: Background Worker (StatefulSet + Storage)
  backgroundWorker:
    enabled: true
    deployType: StatefulSet
    image:
      repository: myregistry.com/worker
      tag: "v1.2.0"
    service:
      enabled: false # Worker không cần service
    pvcs:
      - name: data-disk
        size: 5Gi
        mountPath: /data
```

---

## 🛠️ Chi Tiết Các Tính Năng Nâng Cao

### 1. Environment Variables (Phím tắt `~` thông minh)
Bạn có thể khai báo biến môi trường bằng cặp `KEY: value` thông thường, hoặc dùng các tiền tố đặc biệt sau để tham chiếu tài nguyên khác:

- **ConfigMap Key Reference**: `~cfm:<key-name>:<configmap-name>:<optional: true|false>`
- **Secret Key Reference**: `~scr:<key-name>:<secret-name>:<optional: true|false>`
- **Field Reference (Metadata)**: `~fr:<fieldPath>:<api-version>`
- **Resource Field Reference**: `~rfr:<resource>:<containerName>:<divisor>`

*Ví dụ:*
```yaml
poly:
  myApp:
    enabled: true
    env:
      DB_HOST: "mysql-service"
      DB_PASSWORD: "~scr:password:db-secret:false" # Tham chiếu từ secret db-secret
      POD_IP: "~fr:status.podIP:v1"                # Tham chiếu IP của Pod
```

### 2. EnvFrom (Nạp toàn bộ biến)
Hỗ trợ nạp cấu hình hàng loạt từ ConfigMap (`cfm`) hoặc Secret (`scr`).
- **Cú pháp chuỗi**: `cfm|scr:<tên-resource>:<optional:true|false>:<prefix>`
- **Lưu ý đặc biệt**: Nếu tên resource bắt đầu bằng dấu gạch ngang `-` (ví dụ: `-common-env`), Poly sẽ tự động ghép thêm tên của Helm Release vào trước (ví dụ: `my-release-common-env`).

*Ví dụ:*
```yaml
poly:
  myApp:
    enabled: true
    envFrom:
      - cfm:-app-configs:true     # Tên thực tế: releaseName-app-configs
      - scr:global-secrets:false  # Tên thực tế giữ nguyên: global-secrets
```

### 3. Volume, Volume Mounts & Quick Mount (ConfigMap / Secret)
#### a. Cú pháp chuỗi rút gọn cho `volumeMounts`
Thay vì viết block YAML phức tạp của Kubernetes, bạn có thể map volume nhanh bằng chuỗi phân tách bởi dấu `:`:
- **Cú pháp**: `volumeName:mountPath:readOnly:subPath:mountPropagation`

*Ví dụ:*
```yaml
poly:
  myApp:
    enabled: true
    volumes:
      - name: config-volume
        configMap:
          name: app-config-map
    volumeMounts:
      - config-volume:/etc/config:true:config.json # Mount config.json ở chế độ readOnly
```

#### b. Quick Volume Mount cho `configMaps[]`, `secrets[]` & ExternalSecret
Tương tự `pvcs[].mountPath`, bạn có thể khai báo `mountPath` trực tiếp ngay trong `configMaps[]` hoặc `secrets[]` để Poly tự động sinh `volumes` và `volumeMounts` tương ứng (bỏ qua `mountPath` nếu chỉ muốn tạo resource hoặc dùng cho `envFrom`).

> [!IMPORTANT]
> **Không khai báo trực tiếp dữ liệu Secret (`data` / `stringData`) trong Git.** Để đảm bảo bảo mật GitOps, `values.schema.json` chặn hoàn toàn `secrets[].data` và `secrets[].stringData`. Secret phải được đồng bộ qua **ExternalSecret** (External Secrets Operator) hoặc mount từ **Secret có sẵn** trên cluster (`exists: true`).

- **ConfigMap (`configMaps[]`)**:
  - `create: true` (và `exists` không bật): Poly tạo mới `ConfigMap` tên `<releaseName>-<name>` (hoặc `fullName`), hỗ trợ `isFileType: true/false` và `data`.
  - `exists: true` (hoặc `create: false`): Mount `ConfigMap` có sẵn trên cluster.
- **Secret (`secrets[]`)**:
  - `exists: true` (hoặc không bật `externalSecret.enabled`): Mount `Secret` đã tồn tại trên cluster.
  - `externalSecret.enabled: true` (khi `exists` không bật): Poly sinh manifest `ExternalSecret` (`external-secrets.io/v1` mặc định, kế thừa `default.externalSecret`) để đồng bộ dữ liệu từ Secret Store về K8s Secret đích rồi mount vào container (nếu có `mountPath`).
- **Quy tắc đặt tên với tiền tố `-` (`-prefix` naming)**: Khi mount resource có sẵn (`exists: true` / `create: false`), nếu `name` bắt đầu bằng `-` (ví dụ: `-shared-cm`), Poly tự động ghép `<releaseName>-shared-cm`; nếu không có `-` (ví dụ: `external-cm`), tên được giữ nguyên. Nếu có `fullName`, Poly luôn ưu tiên `fullName`.
- **Các tùy chọn mount hỗ trợ**: `mountPath`, `subPath`, `readOnly` (mặc định `true` cho quick-mount ConfigMap/Secret), `volumeName` (tùy chỉnh tên volume nếu cần, mặc định `cm-<name>` / `secret-<name>`), `defaultMode`, `optional`, và `items` (`key`, `path`).

*Ví dụ:*
```yaml
poly:
  default:
    externalSecret:
      apiVersion: external-secrets.io/v1
      refreshInterval: 1h
      secretStoreRef:
        name: vault-backend
        kind: ClusterSecretStore

  myApp:
    enabled: true
    configMaps:
      # Tạo mới ConfigMap dạng file và mount thẳng vào thư mục
      - name: app-config
        create: true
        isFileType: true
        mountPath: /etc/app/config
        data:
          config.yaml: |
            port: 8080
            env: prod
      # Mount ConfigMap có sẵn dùng -prefix, subPath, defaultMode, optional và items
      - name: -shared-cm
        exists: true
        mountPath: /etc/app/settings.json
        subPath: settings.json
        readOnly: true
        defaultMode: 420
        optional: true
        items:
          - key: raw-settings
            path: settings.json
    secrets:
      # Đồng bộ Secret từ External Secrets Operator và mount một key qua subPath
      - name: db-creds
        mountPath: /etc/db/password
        subPath: password
        defaultMode: 256
        items:
          - key: db-pass
            path: password
        externalSecret:
          enabled: true
          target:
            creationPolicy: Owner
          data:
            - secretKey: db-pass
              remoteRef:
                key: secret/data/db
                property: password
      # Mount Secret có sẵn trên cluster
      - name: tls-secret
        exists: true
        mountPath: /etc/tls
```

### 4. Probes (Healthcheck) & Cơ chế Bật/Tắt Linh Hoạt
Cung cấp tham số `params` định dạng chuỗi `initialDelay:period:timeout:failure:success` để cấu hình nhanh các probe, kết hợp với cơ chế bật/tắt thông minh:

- **Global toggle (`probes.enabled`)**: Đặt `probes.enabled: false` để tắt toàn bộ probes kế thừa từ `default` (mặc định `true` cho `Deployment`/`StatefulSet`/`DaemonSet`, và `false` cho `Job`/`CronJob`).
- **Per-probe toggle (`enabled: true/false`)**: Tắt hoặc bật riêng từng probe (`livenessProbe`, `readinessProbe`, `startupProbe`), ví dụ đặt `readinessProbe.enabled: false` để chỉ giữ lại `livenessProbe`. Trường `enabled` chỉ điều khiển render và không bị xuất ra manifest Kubernetes.
- **Shorthand với `quickConfigs.healthcheckPath`**: Nếu đặt `quickConfigs.healthcheckPath` (ví dụ `"/healthz"`) và bật `probes.livenessProbe.enabled: true` (không cần khai báo `httpGet`), Poly sẽ tự tạo `httpGet` trỏ tới `path: /healthz`, `port: http`, `scheme: HTTP`.
- **`probesOverride`**: Ghi đè trực tiếp toàn bộ block probes với độ ưu tiên cao nhất.

*Ví dụ:*
```yaml
poly:
  myApp:
    enabled: true
    quickConfigs:
      healthcheckPath: "/healthz"
    probes:
      enabled: true
      livenessProbe:
        enabled: true          # Tự sinh httpGet với path: /healthz, port: http
        params: "10:10:5:3:1"  # initialDelay=10s, period=10s, timeout=5s, failure=3, success=1
      readinessProbe:
        enabled: false         # Tắt riêng readinessProbe kế thừa từ default
```

### 5. ArgoCD Image Updater & Độ Ưu Tiên Image Tag
Poly tách riêng độ ưu tiên giữa repository và tag để tương thích hoàn hảo với **ArgoCD Image Updater** (vốn thường cập nhật `image.tag` hoặc `image.repository` mà không sửa `quickConfigs.registry`):

- **Độ ưu tiên Repository**: `image.repository` > phần repo của `quickConfigs.registry`
- **Độ ưu tiên Tag**: `image.tag` > phần tag fallback của `quickConfigs.registry`

Nếu `quickConfigs.registry` có dạng `10.0.0.1:5000/my-app:v1.0.0` (kể cả khi registry có cổng `:5000`), Poly vẫn bóc tách đúng repo và tag fallback, đồng thời ưu tiên `image.tag` nếu được khai báo.

*Ví dụ:*
```yaml
poly:
  myApp:
    enabled: true
    quickConfigs:
      registry: "10.0.0.1:5000/my-app:v1.0.0" # Fallback repo & tag
    image:
      tag: "v2.0.0" # Ghi đè tag -> Kết quả image: "10.0.0.1:5000/my-app:v2.0.0"
```

### 6. Job & CronJob (Smart Defaults)
Khi khai báo `deployType: Job` hoặc `deployType: CronJob`, Poly tự động áp dụng các thiết lập phù hợp để tránh lỗi cấu hình phổ biến trên Kubernetes:

- **Tự động `restartPolicy: OnFailure`**: Tự đặt `podLifecycle.restartPolicy: OnFailure` (và tự chuyển từ `Always` sang `OnFailure` nếu kế thừa từ `default`; vẫn giữ nguyên nếu bạn cấu hình rõ `Never`).
- **Tắt `probes` & `lifecycle` theo mặc định**: Không render `probes` và `lifecycle` (như `default.lifecycle.preStop`) trừ khi app bật tường minh `probes.enabled: true` / `lifecycle.enabled: true` hoặc dùng `*Override`.
- **Tạo `Service` & `Ingress` có điều kiện**: Không tạo `Service` hay `Ingress` dù `default.service.enabled: true`, trừ khi app tự khai báo tường minh `service.enabled: true` hoặc `ingress.enabled: true`.
- **Cấu hình spec qua `workloadCommonConfigs`**: Dùng `workloadCommonConfigs.cronjob` (`schedule`, `concurrencyPolicy`, `successfulJobsHistoryLimit`, `failedJobsHistoryLimit`, `timezone`, `suspend`, `startingDeadlineSeconds`) và `workloadCommonConfigs.job` (`parallelism`, `completions`, `completionMode`, `backoffLimit`, `suspend`, `activeDeadlineSeconds`, `ttlSecondsAfterFinished`).

*Ví dụ:*
```yaml
poly:
  dbMigrator:
    enabled: true
    deployType: Job
    image:
      repository: myregistry.com/db-migrator
      tag: "v1.0.0"
    command: ["/bin/sh", "-c", "migrate.sh"]
    workloadCommonConfigs:
      job:
        backoffLimit: 3
        ttlSecondsAfterFinished: 600

  dailyBackup:
    enabled: true
    deployType: CronJob
    image:
      repository: myregistry.com/db-backup
      tag: "v2.1.0"
    workloadCommonConfigs:
      cronjob:
        schedule: "0 2 * * *"
        concurrencyPolicy: "Forbid"
        timezone: "Asia/Ho_Chi_Minh"
```

### 7. Kubernetes Gateway API (`HTTPRoute` & `GRPCRoute`)
Hỗ trợ tạo trực tiếp các tài nguyên Gateway API (`gateway.networking.k8s.io/v1`) dưới block `gatewayApi`:

- **`gatewayApi.httpRoute`** (`HTTPRoute`) và **`gatewayApi.grpcRoute`** (`GRPCRoute`): Hỗ trợ `enabled`, `name` (hỗ trợ tiền tố `-`), `annotations` (hỗ trợ Helm `tpl`), `parentRefs`, `hostnames`, `rules` và `extraRoutes` (khi cần nhiều route cho cùng một app).
- **Suy luận thông minh**:
  - Nếu bỏ trống `hostnames` và có `quickConfigs.domain`, Poly tự động dùng `[quickConfigs.domain]`.
  - Nếu trong `rules` chưa chỉ định `backendRefs`, Poly tự gắn `backendRefs` trỏ về Service của app (dùng port đầu tiên trong `service.ports` hoặc `quickConfigs.port`).
  - Nếu bỏ trống `rules` hoàn toàn, Poly tự tạo rule mặc định (`PathPrefix /` cho `HTTPRoute`).

*Ví dụ:*
```yaml
poly:
  apiService:
    enabled: true
    quickConfigs:
      domain: "api.example.com"
    ports:
      - "8080:http:TCP"
    service:
      ports:
        - "8080:8080:TCP:http"
    gatewayApi:
      httpRoute:
        enabled: true
        name: -http
        parentRefs:
          - name: main-gateway
            namespace: infra
            sectionName: https
        rules:
          - matches:
              - path:
                  type: PathPrefix
                  value: /api/v1
        extraRoutes:
          - enabled: true
            name: internal-http
            parentRefs:
              - name: internal-gateway
                namespace: infra
            hostnames:
              - internal.example.com
```

### 8. Cilium (`CiliumNetworkPolicy` & `CiliumEnvoyConfig`)
Hỗ trợ khai báo chính sách mạng và cấu hình Envoy của Cilium (`cilium.io/v2`) dưới block `cilium`:

- **`cilium.networkPolicy`** (`CiliumNetworkPolicy`): Hỗ trợ `enabled`, `name` (hỗ trợ tiền tố `-`), `annotations`, `description`, `endpointSelector` (nếu bỏ trống sẽ tự dùng `selectorLabels` của app), `ingress`, `ingressDeny`, `egress`, `egressDeny`, hoặc `specs` (khi cần danh sách nhiều rule spec).
- **`cilium.envoyConfig`** (`CiliumEnvoyConfig`): Hỗ trợ `enabled`, `name` (hỗ trợ tiền tố `-`), `annotations`, `services`, `backendServices` và `resources`.

*Ví dụ:*
```yaml
poly:
  apiService:
    enabled: true
    cilium:
      networkPolicy:
        enabled: true
        description: "Allow ingress from web and egress to kube-dns"
        ingress:
          - fromEndpoints:
              - matchLabels:
                  app: web
            toPorts:
              - ports:
                  - port: "8080"
                    protocol: TCP
        egress:
          - toEndpoints:
              - matchLabels:
                  k8s:io.kubernetes.pod.namespace: kube-system
                  k8s-app: kube-dns
            toPorts:
              - ports:
                  - port: "53"
                    protocol: UDP
      envoyConfig:
        enabled: true
        name: -envoy
        services:
          - name: my-release-api-service
            listener: envoy-listener
        resources:
          - "@type": type.googleapis.com/envoy.config.listener.v3.Listener
            name: envoy-listener
```

### 9. Tích hợp HashiCorp Vault
Tự động cấu hình annotations cho Vault Agent Injector:

```yaml
poly:
  myApp:
    enabled: true
    vault:
      enabled: true
      config:
        path: "secret/data/my-app"
        authPath: "auth/kubernetes"
        role: "my-app-role"
        serviceServer: "https://vault.internal"
      template:
        type: annotation
        name: config.env
        content: |-
          {{ with secret "secret/data/my-app" }}
          {{ range $k, $v := .Data.data }}
          export {{ $k }}="{{ $v }}"
          {{ end }}
          {{ end }}
      runContainer:
        command: ["/bin/sh", "-c"]
        runtimeArgs: [". /vault/secrets/config.env && exec my-app-binary"]
```

### 10. Argo Rollouts (Blue-Green Deployments)
Chỉ cần bật `rollout.enabled: true`, Poly sẽ tự sinh ra resource `Rollout` thay thế/đi kèm `Deployment` tương ứng:

```yaml
poly:
  myApp:
    enabled: true
    rollout:
      enabled: true
      strategy:
        blueGreen:
          activeService: my-app
          previewService: my-app-preview
          autoPromotionEnabled: false
          autoPromotionSeconds: 30
      servicePreview:
        enabled: true
        name: "my-app-preview"
      ingressPreview:
        enabled: true
        name: "-preview"
        hosts:
          - host: preview.example.com
            paths:
              - /:Prefix
```

---

## ✅ Schema Validation & Kiểm Thử

- **Helm `values.schema.json` Validation**: Chart `charts/poly` đi kèm file `charts/poly/values.schema.json` (JSON Schema Draft 7) để Helm tự động xác thực cấu trúc `values.yaml`, kiểu dữ liệu (`replicas`, `port`, ...), các giá trị enum hợp lệ (`deployType`, `image.pullPolicy`, `podLifecycle.restartPolicy`, `service.type`, ...) và **chặn khai báo trực tiếp `secrets[].data` / `secrets[].stringData` trong Git** ngay khi chạy `helm lint`, `helm template`, `helm install` hoặc `helm upgrade`.
- **Regression & Negative Schema Test Suite**: Xem hướng dẫn chi tiết tại [tests/README.md](tests/README.md) và chạy toàn bộ bộ test tự động bằng lệnh:

```console
./tests/run-tests.sh
```

---

## 🔍 Kiểm Tra Cấu Hình Mặc Định

Bạn có thể lấy toàn bộ file cấu hình default và định dạng đầy đủ của Poly bằng lệnh:

```console
# Lấy từ Helm Repository
helm show values https://github.com/cyanwind23/poly > poly-values.yaml

# Hoặc lấy trực tiếp từ file package local (.tgz)
helm show values charts/poly-3.1.0.tgz > poly-values.yaml
```
