# Cloud Storage & Infrastructure Misconfigurations Reference

## Attack Surface Signals
- **S3 Buckets**: `https://{bucket}.s3.amazonaws.com`, `https://s3.amazonaws.com/{bucket}`, CNAMEs pointing to AWS S3.
- **Azure Blob Storage**: `https://{account}.blob.core.windows.net/{container}`.
- **Google Cloud Storage (GCS)**: `https://storage.googleapis.com/{bucket}`, `https://{bucket}.storage.googleapis.com`.
- **CloudWatch RUM**: Exposed JavaScript client monitor tokens in frontend bundles.

## Testing & Verification Methodology
1. **Public Bucket Read / Listing**:
   - AWS CLI: `aws s3 ls s3://{bucket-name} --no-sign-request`
   - REST API: `curl -s https://{bucket-name}.s3.amazonaws.com/?list-type=2` (Look for `<Contents>` tags).
   - Azure: `curl -s "https://{account}.blob.core.windows.net/{container}?restype=container&comp=list"`.
   - GCS: `curl -s https://storage.googleapis.com/storage/v1/b/{bucket-name}/o`.
2. **Public Bucket Write / Tampering**:
   - `aws s3 cp poc.txt s3://{bucket-name}/poc.txt --no-sign-request`
   - If write succeeds: High/Critical severity (enables webshell upload or frontend asset defacement).
3. **Authenticated User Over-Permission (Any AWS User)**:
   - Test if bucket grants read/write to `AuthenticatedUsers` group (any valid AWS account):
     `aws s3 ls s3://{bucket-name} --profile my_personal_account`
4. **CloudWatch RUM Weaponization**:
   - Check if RUM client role has over-permissive IAM policies allowing PutEvents or CloudWatch log reads.

## Exploit Chains
- **Public S3 Bucket Write → Overwrite Frontend JavaScript (`app.js`) → Stored XSS / Customer Session Theft**.
- **Public Azure Blob Read → Backup Database Snapshot (`.bak` / `.sql`) → Production Credentials Dump**.
