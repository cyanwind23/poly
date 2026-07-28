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
  - **Volume & Volume Mounts**: Map PV/PVC với cú pháp chuỗi phân tách bằng dấu hai chấm `:`.
  - **Probes**: Định nghĩa health check (Liveness, Readiness, Startup) nhanh gọn.
- **Tích hợp Cloud-Native mạnh mẽ**:
  - **Argo Rollouts**: Hỗ trợ chiến lược Blue-Green kèm Service & Ingress Preview.
  - **HashiCorp Vault**: Tích hợp Vault Agent Injector tự động.
  - **Prometheus**: Hỗ trợ tạo nhanh `ServiceMonitor` để thu thập metrics.

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
    version: "3.0.5" # Sử dụng version phù hợp
```

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

### 3. Volume & Volume Mounts rút gọn
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

### 4. Probes (Healthcheck)
Cung cấp tham số `params` định dạng chuỗi `initialDelay:period:timeout:failure:success` để cấu hình nhanh các probe.

*Ví dụ:*
```yaml
poly:
  myApp:
    enabled: true
    quickConfigs:
      healthcheckPath: "/healthz"
    probes:
      livenessProbe:
        httpGet:
          request: /:http
        params: "10:10:5:3:1" # initialDelay=10s, period=10s, timeout=5s, failure=3, success=1
```

### 5. Tích hợp HashiCorp Vault
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

### 6. Argo Rollouts (Blue-Green Deployments)
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

## 🔍 Kiểm Tra Cấu Hình Mặc Định

Bạn có thể lấy toàn bộ file cấu hình default và định dạng đầy đủ của Poly bằng lệnh:

```console
# Lấy từ Helm Repository
helm show values https://github.com/cyanwind23/poly > poly-values.yaml

# Hoặc lấy trực tiếp từ file package local (.tgz)
helm show values charts/poly-3.0.5.tgz > poly-values.yaml
```
