# Poly Development Guidelines

Document này quy định quy trình phát triển, chiến lược rẽ nhánh (Git Flow) và quy chuẩn commit (Conventional Commits) cho dự án **Poly Helm Chart**.

---

## 1. Git Branching Model

Dự án áp dụng mô hình **Git Flow với Release Branch**:

### Nhánh chính (Core Branches):
- **`main`**: Nhánh Production ổn định.
  - Mọi commit merge vào `main` sẽ kích hoạt GitHub Actions (`.github/workflows/release.yml`) tự động đóng gói và release Helm Chart lên GitHub Releases / Pages.
- **`release/vX.Y.Z`**: Nhánh tích hợp tính năng cho từng Milestone (Ví dụ: `release/v3.1.0`).
  - Dùng để tích hợp tất cả các tính năng, refactor và bugfix trước khi chốt release vào `main`.
  - Các nhánh `release/vX.Y.Z` được giữ lại trên repository để làm mốc tham chiếu lịch sử phiên bản.

### Chiến lược phân tách & tích hợp nhánh trong Milestone:
- **Mặc định tách nhánh độc lập từ `release/vX.Y.Z`**:
  - Mỗi task/issue phải tách trực tiếp từ `release/vX.Y.Z`, giữ phạm vi gọn, test pass xong là mở PR và **Squash and Merge** sớm (`1 feature = 1 commit` sạch sẽ, dễ hoãn hoặc revert nếu cần).
- **Thứ tự triển khai tối ưu trong một Milestone**:
  1. **Refactor kiến trúc lớn** (như tách partial templates) thực hiện trước hoặc cô lập để tránh xung đột với nhánh feature.
  2. **Các Feature độc lập** tách song song từ `release/vX.Y.Z` và merge sớm ngay khi đạt chuẩn.
  3. **Nhóm hoàn thiện & chốt release** (`values.schema.json`, `README.md`, nâng `version` trong `Chart.yaml` + chạy `./tests/run-tests.sh --update`) thực hiện sau khi các feature đã merge về `release/vX.Y.Z`.
- **Ngoại lệ Stacked PRs (PR chuỗi)**:
  - Chỉ xếp chuỗi (tối đa 2–3 tầng) khi PR sau **bắt buộc** phụ thuộc vào helper/API của PR trước đang chờ review.
  - Khi merge PR chuỗi, ưu tiên **Rebase and Merge** (hoặc **Merge commit**) để giữ nguyên base commit; nếu dùng *Squash and Merge* ở nhánh dưới, cần chạy `git rebase --onto` cho các nhánh xếp trên để tránh lệch diff/conflict.

---

## 2. Naming Conventions

Mọi nhánh làm việc phải được checkout từ `release/vX.Y.Z` (hoặc `main` nếu là hotfix) theo định dạng:

`<type>/#<issue-id>-<short-description>`

### Types:
- `feat/`: Tính năng mới (ví dụ: `feat/#1-job-cronjob-support`)
- `fix/`: Sửa lỗi (ví dụ: `fix/#6-app-name-validation`)
- `refactor/`: Cấu trúc lại mã nguồn / templates mà không đổi tính năng (ví dụ: `refactor/#4-split-podtemplate`)
- `docs/`: Tài liệu và ví dụ cấu hình (ví dụ: `docs/#8-update-readme-v3.1.0`)
- `test/`: Bộ test cases và validation scripts (ví dụ: `test/#9-helm-template-tests`)

---

## 3. Commit Message Standards

Commit message tuân theo quy chuẩn **Conventional Commits**:

```text
<type>(<scope>): <description> (#<issue-id>)
```

### Components:
- **`type`**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`.
- **`scope`**: Scope bị ảnh hưởng (ví dụ: `templates`, `helpers`, `schema`, `ci`, `docs`).
- **`description`**: Mô tả ngắn gọn thay đổi (khuyến khích tiếng Anh hoặc tiếng Việt kỹ thuật).
- **`#<issue-id>`**: ID của GitHub Issue liên quan.

### Examples:
- `feat(templates): add CronJob & Job template support (#1)`
- `fix(helpers): ensure app name passes k8s DNS validation (#6)`
- `refactor(templates): split _podtemplate.yaml into modular partials (#4)`
- `docs(readme): add KEDA configuration guide (#8)`

---

## 4. Pull Request & Verification Workflow

Trước khi tạo Pull Request, bắt buộc chạy kiểm tra cục bộ:

```bash
# 1. Kiểm tra cú pháp Chart
helm lint charts/poly

# 2. Chạy toàn bộ bộ test đối chiếu & schema validation
./tests/run-tests.sh

# 3. Render thử nghiệm với cấu hình mặc định (nếu cần kiểm tra nhanh)
helm template test-release charts/poly -f charts/poly/values.yaml
```

### Workflow:
1. Push nhánh làm việc lên GitHub (`origin`).
2. Tạo Pull Request trỏ vào target branch `release/vX.Y.Z`.
3. Đảm bảo `helm lint` và tất cả test case trong `./tests/run-tests.sh` đều passed.
4. Merge PR bằng **Squash and Merge** (với nhánh độc lập) hoặc **Rebase and Merge** (với chuỗi phụ thuộc).
