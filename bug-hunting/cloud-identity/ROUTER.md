---
name: cloud-identity-router
description: Signal table for cloud infra, Kubernetes, CI/CD, and enterprise identity (SAML/Okta/Entra/LDAP) hunting.
---

# Cloud & Enterprise Identity Hunting — Router

Scan this router when evaluating cloud infrastructure, container orchestration clusters (Kubernetes), continuous integration / delivery pipelines (CI/CD), enterprise single sign-on (SSO) systems (SAML, Okta, Entra ID), network perimeters (VPNs), and credential attack surfaces.

---

## 1. Cloud Infrastructure, Kubernetes & CI/CD

| Attack Surface | Observable Signals (URL, Headers, Wire Format) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **Cloud Storage Misconfig** | S3 bucket URLs, Azure Blob containers, GCP storage buckets, CloudWatch RUM | Send unauthenticated `GET /?list-type=2` or `aws s3 ls`; verify XML/JSON bucket directory listing or public write | `references/cloud-misconfig.md` |
| **Cloud IAM & PrivEsc** | Leaked `AKIA...` keys, GCP service account JSON, Azure SP credentials | Run read-only `aws sts get-caller-identity`; simulate policy evaluation for privilege escalation paths | `references/iam.md` |
| **Kubernetes API & Nodes** | Ports `6443`, `8443`, `10250` (kubelet), `10255`, `2379` (etcd), pod tokens | Query `https://target:6443/api/v1/namespaces/default/pods` unauthenticated; verify anonymous API access | `references/k8s.md` |
| **CI/CD & GitHub Actions** | `.github/workflows/*.yml`, Jenkins `:8080`, GitLab CI, `pull_request_target` triggers | Check workflow files for unquoted `${{ github.event.issue.body }}` in `run:` step or script console exposure | `references/cicd.md` |

---

## 2. Enterprise Identity & SSO

| Protocol / Provider | Observable Signals (URL, Headers, Wire Format) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **SAML / SSO Attacks** | `SAMLRequest`, `SAMLResponse`, base64 XML envelopes, `/saml/sso`, `/adfs/ls/` | Modify assertion NameID and strip `<ds:Signature>` or perform XML Signature Wrapping (XSW); test signature bypass | `references/saml.md` |
| **LDAP & NTLM Info** | Ports `389`, `636`, `445`, `WWW-Authenticate: NTLM`, NTLM Type 2 challenge | Send dummy NTLM Type 1 message; decode Type 2 response to extract internal NetBIOS name, domain, and OS build | `references/ldap-ntlm.md` |
| **Okta Identity** | `*.okta.com`, `*.oktapreview.com`, `/login/default`, Okta Verify push prompts | Query `/.well-known/webfinger` or test user enumeration via timing differentials on password submission | `references/okta.md` |
| **Microsoft 365 / Entra ID** | `login.microsoftonline.com`, `autodiscover.target.com`, AADSTS error codes | Probe `/getuserrealm.srf` for Managed vs Federated domain status; evaluate Smart Lockout threshold limits | `references/m365-entra.md` |
| **Enterprise VPN Gateways**| Ivanti Connect Secure, Fortinet SSL-VPN, Palo Alto GlobalProtect, Cisco AnyConnect | Probe vendor-specific endpoints (`/dana-na/`, `/remote/login`, `/global-protect/`); check CVE signature matrix | `references/vpn.md` |

---

## 3. Credential & Password Attacks

| Surface / Mechanism | Observable Signals (URL, Headers, Wire Format) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **Credential Spraying & Auth**| Legacy authentication endpoints, ActiveSync, ADFS, Single-Password multi-user sprays | Validate lockout threshold (e.g. 10 attempts / 60 min); spray 1 high-probability password across employee accounts | `references/credential-attack.md` |
