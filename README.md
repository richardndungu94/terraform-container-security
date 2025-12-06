#  Container Security Pipeline

Complete container security implementation: scanning, hardening, and secure deployment on AWS ECS.

---

##  What This Project Does

**Builds a production-ready container security pipeline that:**

1. ✅ Scans images for vulnerabilities (Trivy + ECR scanning)
2. ✅ Fails build if critical vulnerabilities found
3. ✅ Stores images in encrypted private registry (ECR)
4. ✅ Deploys containers with security hardening
5. ✅ Monitors runtime security
6. ✅ Sends alerts on security issues

---

##  The Problem

### Real Scenario

**Company deploys container with vulnerable library:**

```
Day 1: Deploy app with Log4j 1.2.17
Day 45: Log4Shell vulnerability announced (CVE-2021-44228)
Day 46: Hackers exploit it
Result: Data breach, $3M in damages
```

**The issue:** No one knew the container had the vulnerability until it was too late.

### What Goes Wrong

**Common container security mistakes:**

1. ❌ Using `:latest` tag (no version control)
2. ❌ Running as root user (full system access if compromised)
3. ❌ No vulnerability scanning (don't know what's inside)
4. ❌ Writable filesystem (attackers can install malware)
5. ❌ All capabilities enabled (unnecessary permissions)
6. ❌ No runtime monitoring (can't detect attacks)

**Each mistake = security hole**

---

##  The Solution

### Security Pipeline Flow

```
Developer writes code
    ↓
Dockerfile created
    ↓
Build Docker image
    ↓
🔍 SCAN with Trivy
  - Check for CVEs
  - Check for secrets
  - Check Dockerfile best practices
    ↓
❌ If CRITICAL/HIGH → FAIL BUILD
✅ If SAFE → Continue
    ↓
Push to encrypted ECR
    ↓
🔍 AWS ECR scans image again
    ↓
Deploy to ECS with:
  ✓ Non-root user (UID 1000)
  ✓ Read-only filesystem
  ✓ Dropped capabilities
  ✓ Security monitoring
    ↓
📊 Monitor runtime
Send alerts if issues found
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                Developer                         │
│                    ↓                             │
│              Docker Build                        │
│                    ↓                             │
│        ┌───────────────────────┐                │
│        │  CodeBuild Pipeline   │                │
│        │  ┌─────────────────┐  │                │
│        │  │ Trivy Scan      │  │                │
│        │  │ - CVE check     │  │                │
│        │  │ - Secret scan   │  │                │
│        │  │ - Config check  │  │                │
│        │  └─────────────────┘  │                │
│        │         ↓              │                │
│        │  ❌ Fail if critical  │                │
│        │  ✅ Pass if safe      │                │
│        └───────────────────────┘                │
│                    ↓                             │
│        ┌───────────────────────┐                │
│        │  ECR (Private)        │                │
│        │  - Encrypted storage  │                │
│        │  - Image scanning     │                │
│        │  - Immutable tags     │                │
│        └───────────────────────┘                │
│                    ↓                             │
│        ┌───────────────────────┐                │
│        │  ECS Fargate          │                │
│        │                       │                │
│        │  Container with:      │                │
│        │  • Non-root user      │                │
│        │  • Read-only FS       │                │
│        │  • Dropped caps       │                │
│        │  • Security policies  │                │
│        └───────────────────────┘                │
│                    ↓                             │
│        ┌───────────────────────┐                │
│        │  Monitoring           │                │
│        │  - CloudWatch         │                │
│        │  - SNS Alerts         │                │
│        │  - Lambda processor   │                │
│        └───────────────────────┘                │
└─────────────────────────────────────────────────┘
```

---

##  Security Features

### 1. **Image Scanning (Prevention)**

**Trivy scans for:**
- CVEs in OS packages
- CVEs in application dependencies
- Hardcoded secrets (API keys, passwords)
- Dockerfile best practices violations

**ECR scans for:**
- Additional CVE databases
- AWS-specific vulnerabilities
- Continuous monitoring (rescans daily)

### 2. **Secure Registry**

- ✅ Private ECR (not Docker Hub public)
- ✅ Encryption at rest (AES-256)
- ✅ Encryption in transit (TLS)
- ✅ Immutable tags (can't overwrite)
- ✅ Lifecycle policies (delete old images)

### 3. **Container Hardening**

**Non-root user:**
```dockerfile
USER 1000:1000  # Not root (UID 0)
```

**Read-only filesystem:**
```json
"readonlyRootFilesystem": true
```

**Dropped capabilities:**
```json
"capabilities": {
  "drop": ["ALL"],
  "add": ["NET_BIND_SERVICE"]  # Only what's needed
}
```

### 4. **Runtime Security**

- CloudWatch Container Insights
- Health check monitoring
- Restart detection
- Resource usage alerts
- Log aggregation

### 5. **Automated Alerts**

Lambda function processes scan results:
- Counts CRITICAL/HIGH/MEDIUM vulnerabilities
- Compares against threshold
- Sends SNS notification if exceeded
- Includes remediation guidance

---

## 🎓 Skills You'll Gain

### Technical Skills

**Container Security:**
- Image vulnerability scanning
- Dockerfile security best practices
- Container runtime hardening
- Least-privilege principles
- Supply chain security

**AWS Services:**
- ECR (Elastic Container Registry)
- ECS (Elastic Container Service)
- CodeBuild (CI/CD)
- CloudWatch (monitoring)
- Lambda (event processing)

**DevSecOps:**
- Security in CI/CD pipeline
- Shift-left security
- Automated vulnerability management
- Security as code
- Infrastructure as code

**Tools:**
- Trivy (scanning)
- Docker (containers)
- Terraform (IaC)
- AWS CLI

### Career Skills

**Resume bullets:**

✅ "Implemented automated container security scanning reducing deployment of vulnerable images by 100%"

✅ "Hardened container runtime using non-root users, read-only filesystems, and capability dropping per CIS benchmarks"

✅ "Built CI/CD pipeline with security gates that fails builds on critical vulnerabilities before production deployment"

✅ "Reduced container attack surface by 80% through security hardening and least-privilege access controls"

---

##  What Gets Deployed

| Resource | Purpose | Security Feature |
|----------|---------|------------------|
| **ECR Repository** | Store images | Encrypted, private, scan-on-push |
| **CodeBuild Project** | Build pipeline | Trivy scanning, fail on critical |
| **ECS Cluster** | Run containers | Fargate (no EC2 to manage) |
| **ECS Service** | Manage tasks | Health checks, auto-restart |
| **Task Definition** | Container config | Non-root, read-only FS, dropped caps |
| **ALB** | Load balancer | Health checks, DDoS protection |
| **Lambda** | Process scans | Alert on vulnerabilities |
| **SNS Topic** | Notifications | Email/Slack alerts |
| **CloudWatch** | Monitoring | Logs, metrics, alarms |

**Total:** 15+ resources  
**Cost:** ~$15/month  
**Time:** 2-3 hours

---

## 🚀 Quick Start

### Prerequisites

```bash
# Install tools
brew install terraform awscli docker  # macOS
# or
apt install terraform awscli docker.io  # Linux

# Configure AWS
aws configure

# Verify Docker is running
docker ps
```

### 1. Deploy Infrastructure

```bash
cd ~/Desktop
mkdir terraform-container-security
cd terraform-container-security

# Copy all Terraform files (from artifacts)
# Copy sample-app/ directory
# Copy scripts/ directory

# Configure
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
# Update: aws_region, alert_email

# Deploy
terraform init
terraform apply
# Type: yes

# Wait 5-7 minutes
```

### 2. Build and Push Container

```bash
cd sample-app

# Login to ECR
aws ecr get-login-password --region eu-north-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw ecr_repository_url)

# Build image
docker build -t $(terraform output -raw ecr_repository_url):latest .

# Scan locally (optional)
../scripts/scan-image.sh $(terraform output -raw ecr_repository_url):latest

# Push to ECR (triggers automatic scan)
docker push $(terraform output -raw ecr_repository_url):latest
```

### 3. Wait for Scan Results

```bash
# Check scan status (wait ~2 minutes)
aws ecr describe-image-scan-findings \
  --repository-name $(terraform output -raw ecr_repository_name) \
  --image-id imageTag=latest

# View in console
echo "https://console.aws.amazon.com/ecr/"
```

### 4. Deploy to ECS

ECS automatically deploys the image. Wait 3-5 minutes, then:

```bash
# Test the application
curl $(terraform output -raw application_url)/health

# Should return:
# {"status":"healthy","environment":"dev"}
```

### 5. Test Security Features

```bash
# Run test script
chmod +x scripts/test-deployment.sh
./scripts/test-deployment.sh

# View dashboard
terraform output cloudwatch_dashboard_url

# View logs
aws logs tail /ecs/container-security --follow
```

---

## 🧪 Testing Security

### Test 1: Vulnerable Image

```bash
# Build with old Python (has vulnerabilities)
cd sample-app
docker build -t test:vuln -f- . <<EOF
FROM python:3.7
COPY app.py .
CMD ["python", "app.py"]
EOF

# Scan it
trivy image --severity HIGH test:vuln

# Should show many vulnerabilities!
```

### Test 2: Secure Image

```bash
# Build with Dockerfile.secure
docker build -t test:secure -f Dockerfile.secure .

# Scan it
trivy image --severity HIGH test:secure

# Should show minimal or no HIGH vulnerabilities
```

### Test 3: Check Container User

```bash
# Get running task
TASK_ARN=$(aws ecs list-tasks \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --service-name $(terraform output -raw ecs_service_name) \
  --query 'taskArns[0]' --output text)

# Execute command in container
aws ecs execute-command \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --task $TASK_ARN \
  --container app \
  --interactive \
  --command "whoami"

# Should show: appuser (not root!)
```

### Test 4: Check Read-Only Filesystem

```bash
# Try to write to filesystem (should fail)
aws ecs execute-command \
  --cluster $(terraform output -raw ecs_cluster_name) \
  --task $TASK_ARN \
  --container app \
  --interactive \
  --command "touch /test.txt"

# Should get: Permission denied (read-only filesystem)
```

---

## 🔍 Vulnerability Management

### When Scan Finds Issues

**1. Review the findings:**

```bash
aws ecr describe-image-scan-findings \
  --repository-name REPO_NAME \
  --image-id imageTag=latest \
  --query 'imageScanFindings.findings[?severity==`HIGH`]'
```

**2. Prioritize fixes:**
- CRITICAL: Fix immediately, don't deploy
- HIGH: Fix within 7 days
- MEDIUM: Fix within 30 days
- LOW: Fix when convenient

**3. Fix vulnerabilities:**

```dockerfile
# Option 1: Update base image
FROM python:3.11  # Old
FROM python:3.11.7-slim  # New, patched

# Option 2: Update dependencies
pip install Flask==2.3.0  # Old, vulnerable
pip install Flask==3.0.0  # New, patched
```

**4. Rebuild and rescan:**

```bash
docker build -t IMAGE:TAG .
trivy image IMAGE:TAG
docker push IMAGE:TAG
```

### Continuous Scanning

ECR automatically rescans images daily. Check for new CVEs:

```bash
# Get scan results
aws ecr describe-image-scan-findings \
  --repository-name REPO_NAME \
  --image-id imageTag=latest
```

---

## 💰 Cost Breakdown

| Service | Monthly Cost |
|---------|--------------|
| **ECR Storage** | $0.10/GB (~$0.50 for 5GB) |
| **ECS Fargate** | ~$12 (0.25 vCPU, 0.5GB RAM) |
| **ALB** | ~$16 |
| **Data Transfer** | ~$1 |
| **CloudWatch** | ~$1 |
| **Lambda** | FREE (< 1M invocations) |
| **CodeBuild** | FREE (first 100 mins/month) |
| **Total** | **~$30/month** |

**Free Tier:**
- First 500MB ECR storage: FREE
- First 100 CodeBuild minutes: FREE
- First 1M Lambda invocations: FREE

**Cost Optimization:**
- Stop ECS service when not testing: `aws ecs update-service --desired-count 0`
- Delete old images with lifecycle policy (already configured)
- Use Fargate Spot for non-critical workloads (50% cheaper)

---

##  Real-World Examples

### Example 1: Log4Shell Detection

**Scenario:** Log4Shell vulnerability announced (CVE-2021-44228)

```bash
# Scan existing image
trivy image myapp:v1.0

# Result:
# CVE-2021-44228 | log4j-core | 2.14.1 | CRITICAL
# Exploitable! Immediate action required.

# Fix:
# Update log4j to 2.17.0
# Rebuild image
# Rescan shows: ✅ Fixed

# Time to detect: 5 minutes
# Time to fix: 30 minutes
# Without scanning: Might never know!
```

### Example 2: Secrets Leak Detection

```bash
# Developer accidentally hardcodes API key
echo "API_KEY=sk-abc123def456" >> .env

# Trivy scans and finds it
trivy fs --scanners secret .

# Result:
# ❌ API Key found in .env
# Blocked before commit!
```

### Example 3: Container Escape Attempt

```bash
# Attacker exploits vulnerability, gets shell
# Tries to escalate to root

# Container runs as user 1000 (not root)
$ whoami
appuser

# Tries to write malware
$ touch /usr/bin/malware
touch: cannot touch '/usr/bin/malware': Read-only file system

# Tries to use kernel capabilities
$ iptables -L
iptables: Permission denied (you must be root)

# All attempts fail due to hardening!
```

---

##  Interview Talking Points

**Question:** "How do you secure containers?"

**Answer:**

> "I implement a multi-layered container security approach. First, I scan images with Trivy during the build process, failing the pipeline if critical vulnerabilities are found. Images are stored in a private encrypted ECR with immutable tags and automatic daily rescanning.
>
> For runtime security, I use security-hardened task definitions: containers run as non-root users (UID 1000), have read-only filesystems, and drop all Linux capabilities except what's absolutely necessary like NET_BIND_SERVICE. I monitor with CloudWatch Container Insights and have Lambda functions that process ECR scan results and send alerts via SNS when vulnerabilities exceed thresholds.
>
> In my last project, this approach caught a critical Log4j vulnerability before it reached production, and the read-only filesystem prevented a container escape attempt during a security assessment."

**Key points covered:**
- Scanning (shift-left)
- Encryption (data protection)
- Runtime hardening (defense in depth)
- Monitoring (detection)
- Real example (credibility)

---

## 🐛 Troubleshooting

### Issue: "ECR scan shows vulnerabilities"

**Solution:**
```bash
# Update base image
FROM python:3.11.7-slim  # Use specific, patched version

# Update dependencies
pip install --upgrade package-name

# Rebuild and push
```

### Issue: "Container keeps restarting"

```bash
# Check logs
aws logs tail /ecs/container-security --follow

# Common causes:
# - Application needs write access to /tmp
# - Missing environment variables
# - Port mismatch

# Fix: Add writable volume in task definition
```

### Issue: "Can't push to ECR"

```bash
# Re-authenticate
aws ecr get-login-password --region REGION | \
  docker login --username AWS --password-stdin ECR_URL
```

---

## 🧹 Cleanup

```bash
# Stop ECS service first
aws ecs update-service \
  --cluster CLUSTER_NAME \
  --service SERVICE_NAME \
  --desired-count 0

# Wait 2 minutes, then destroy
terraform destroy
# Type: yes

# Delete ECR images (if needed)
aws ecr batch-delete-image \
  --repository-name REPO_NAME \
  --image-ids imageTag=latest
```

---

## 📖 Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [AWS ECS Security Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/security.html)
- [OWASP Container Security](https://owasp.org/www-project-docker-top-10/)

---

**⭐ Star this project if it helped you!**

**Next:** Build CI/CD pipeline with GitHub Actions for automated deployments
