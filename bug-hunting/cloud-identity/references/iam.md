# Cloud IAM & Privilege Escalation Reference

## Attack Surface Signals
- Leaked credentials in git repositories, JS bundles, mobile apps, or SSRF metadata endpoints:
  - AWS: `AKIA...` (Standard Access Key), `ASIA...` (Temporary STS Session Key).
  - GCP: Service Account JSON files containing `"type": "service_account"`, `"private_key": "..."`.
  - Azure: Client ID + Client Secret + Tenant ID combinations.

## AWS IAM Enumeration & Privilege Escalation (Read-Only Gate)
1. **Credential Identity Validation (First Step)**:
   - `aws sts get-caller-identity` (Extracts Account ID, ARN, and UserId).
   - Check active session policies: `aws iam get-user`, `aws iam list-attached-user-policies --user-name <name>`.
2. **Top AWS IAM Privilege Escalation Vectors**:
   - **`iam:CreateAccessKey`**: Create new access key on higher-privileged user (`aws iam create-access-key --user-name admin`).
   - **`iam:CreatePolicyVersion`**: Set new policy version with `{"Effect":"Allow","Action":"*","Resource":"*"}`.
   - **`iam:AttachUserPolicy` / `iam:AttachRolePolicy`**: Attach `AdministratorAccess` policy to own identity.
   - **`iam:PutUserPolicy` / `iam:PutRolePolicy`**: Write inline administrator policy.
   - **`iam:SetDefaultPolicyVersion`**: Revert to older, unrestricted policy version.
   - **`iam:PassRole` + `ec2:RunInstances` / `lambda:CreateFunction`**: Launch compute instance with attached admin role and execute script.
   - **`sts:AssumeRole`**: Assume IAM role across accounts or trust boundaries.

## GCP & Azure PrivEsc Essentials
- **GCP**: Check `roles/iam.serviceAccountTokenCreator` to impersonate higher-privileged service accounts (`gcloud auth print-access-token --impersonate-service-account=...`).
- **Azure**: Inspect Service Principal RBAC roles (`Contributor`, `Owner`, `User Access Administrator`).

## Exploit Chains
- **SSRF Metadata IAM Key Extraction → `iam:CreatePolicyVersion` → Full Cloud Account Takeover**.
