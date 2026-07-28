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

# 2. Render thử nghiệm templates
helm template test-release charts/poly -f charts/poly/values.yaml
```

### Workflow:
1. Push nhánh làm việc lên GitHub.
2. Tạo Pull Request trỏ vào target branch `release/vX.Y.Z`.
3. Đảm bảo tất cả các test case `helm template` passed.
4. Merge PR bằng phương thức **Squash and Merge** hoặc **Rebase and Merge**.
