# Secret Manager Integration Checklist

Tài liệu này tóm tắt toàn bộ quy trình chuyển các Kubernetes Secret sang quản lý bằng **Google Secret Manager** và **Terraform**. Sử dụng như một checklist để lặp lại nhanh trong những môi trường khác.

---

## 1. Chuẩn bị

- Đã cài đặt `gcloud`, `terraform >= 1.6`
- Đăng nhập `gcloud auth login` với tài khoản **Owner** của project `mlops-476305`
- Có file JSON key cho service account Terraform (ví dụ `terraform-state-admin-key.json`)

## 2. Tạo secret trên GCP

Tạo một secret cho mỗi giá trị nhạy cảm (plaintext – **không base64**):

```bash
echo -n "YOUR_GEMINI_KEY" | gcloud secrets create gemini-api-key \
  --project=mlops-476305 \
  --replication-policy="automatic" \
  --data-file=-

echo -n "YOUR_LANGFUSE_PUBLIC" | gcloud secrets create langfuse-public-key \
  --project=mlops-476305 --replication-policy="automatic" --data-file=-

echo -n "YOUR_LANGFUSE_SECRET" | gcloud secrets create langfuse-secret-key \
  --project=mlops-476305 --replication-policy="automatic" --data-file=-

# Lặp lại cho oauth2-proxy (client id, client secret, cookie secret, ...)
```

## 3. Cấp quyền cho service account Terraform

```bash
gcloud projects add-iam-policy-binding mlops-476305 \
  --member="serviceAccount:terraform-state-admin@mlops-476305.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding mlops-476305 \
  --member="serviceAccount:terraform-state-admin@mlops-476305.iam.gserviceaccount.com" \
  --role="roles/secretmanager.viewer"
```

> Các lệnh trên phải chạy bằng tài khoản Owner (user), **không** phải service account.

## 4. Cấu hình Terraform

1. **versions.tf** – bổ sung provider Google
   ```hcl
   terraform {
     required_providers {
       google = {
         source  = "hashicorp/google"
         version = "~> 5.0"
       }
     }
   }
   ```

2. **variables.tf** – khai báo biến
   ```hcl
   variable "project_id" {
     type = string
   }

   variable "google_credentials_path" {
     type = string
   }
   ```

3. **terraform.tfvars** – nhập giá trị
   ```hcl
   project_id              = "mlops-476305"
   google_credentials_path = "/Users/nguyenkhacvy/terraform-state-admin-key.json"
   ```

4. **providers.tf** – cấu hình provider Google sử dụng file key
   ```hcl
   provider "google" {
     project     = var.project_id
     region      = "asia-southeast1"
     credentials = file(var.google_credentials_path)
   }
   ```

5. **main.tf** – thêm data sources & resource secret
   ```hcl
   data "google_secret_manager_secret_version" "gemini" {
     project = var.project_id
     secret  = "gemini-api-key"
     version = "latest"
   }

   resource "kubernetes_secret" "gemini" {
     metadata {
       name      = "gemini-secret"
       namespace = kubernetes_namespace.llm_app.metadata[0].name
     }
     type = "Opaque"
     data = {
       GEMINI_API_KEY = base64encode(data.google_secret_manager_secret_version.gemini.secret_data)
     }
   }

   # Secret Langfuse tách riêng
   data "google_secret_manager_secret_version" "langfuse_public" {
     project = var.project_id
     secret  = "langfuse-public-key"
     version = "latest"
   }

   data "google_secret_manager_secret_version" "langfuse_secret" {
     project = var.project_id
     secret  = "langfuse-secret-key"
     version = "latest"
   }

   resource "kubernetes_secret" "langfuse" {
     metadata {
       name      = "langfuse-secret"
       namespace = kubernetes_namespace.llm_app.metadata[0].name
     }
     type = "Opaque"
     data = {
       LANGFUSE_PUBLIC_KEY = base64encode(data.google_secret_manager_secret_version.langfuse_public.secret_data)
       LANGFUSE_SECRET_KEY = base64encode(data.google_secret_manager_secret_version.langfuse_secret.secret_data)
     }
   }

   # Tương tự cho oauth2-proxy (client id/secret/cookie)
   ```

6. **Deployment** – update env để trỏ vào secret mới (ví dụ backend)
   ```hcl
   env {
     name = "LANGFUSE_PUBLIC_KEY"
     value_from {
       secret_key_ref {
         name = "langfuse-secret"
         key  = "LANGFUSE_PUBLIC_KEY"
       }
     }
   }
   ```

## 5. Import secret hiện có (nếu cluster đã có)

```bash
terraform import kubernetes_secret.gemini llm-app/gemini-secret
terraform import kubernetes_secret.oauth2_proxy llm-app/oauth2-proxy-secret
terraform import kubernetes_secret.langfuse llm-app/langfuse-secret   # nếu đã tự tạo trước
```

Nếu secret chưa tồn tại, bỏ qua bước import – Terraform sẽ tạo mới trong lần apply.

## 6. Kiểm tra và áp dụng

```bash
terraform plan   # Kiểm tra diff
terraform apply  # Thực thi khi diff đúng mong muốn
```

Sau apply, có thể xác minh:
```bash
kubectl get secret gemini-secret -n llm-app -o yaml
kubectl get secret oauth2-proxy-secret -n llm-app -o yaml
```

## 7. Ghi chú vận hành

- **Rotate secret**: tạo phiên bản mới trong Secret Manager (`gcloud secrets versions add ...`), sau đó `terraform apply` để cập nhật Kubernetes secret.
- **Không commit plaintext**: file `k8s/secret.yaml` cũ nên xoá hoặc giữ trống.
- **Credential Terraform**: bảo đảm biến `GOOGLE_APPLICATION_CREDENTIALS` hoặc `credentials = file(...)` trỏ đúng JSON key của service account đã có quyền.
- **Diff trước apply**: luôn xem `terraform plan` để chắc chắn chỉ cập nhật secret, không chạm các resource khác ngoài ý muốn.

---

Sử dụng tài liệu này như checklist mỗi khi cần tái triển khai secret management cho môi trường mới.

