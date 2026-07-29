# 🧪 Poly Helm Template Test Suite

Bộ test case kiểm thử `helm template` và đối chiếu regression output của Helm Chart `poly`.

## 📁 Cấu trúc thư mục

```text
tests/
├── cases/
│   └── 01-image-updater-priority/
│       ├── values.yaml          # File values cấu hình test case
│       └── expected.yaml        # Golden output manifest mong đợi
├── run-tests.sh                 # Script chạy test suite tự động
└── README.md
```

## 🚀 Hướng dẫn sử dụng

### 1. Chạy kiểm thử toàn bộ test cases
```bash
./tests/run-tests.sh
```

### 2. Cập nhật (Cập nhật Golden expected output khi thay đổi tính năng)
Khi bạn thêm tính năng mới hoặc cố ý thay đổi template và muốn cập nhật `expected.yaml`:
```bash
./tests/run-tests.sh --update
```

### 3. Thêm một test case mới
1. Tạo thư mục mới trong `tests/cases/`, ví dụ: `tests/cases/02-probes-toggle/`.
2. Tạo file `values.yaml` chứa cấu hình test.
3. Chạy `./tests/run-tests.sh --update` để tự động tạo `expected.yaml`.
