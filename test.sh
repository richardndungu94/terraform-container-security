#!/bin/bash


# Check root files
for f in main.tf variables.tf outputs.tf ecr.tf codebuild.tf ecs.tf iam.tf monitoring.tf security.tf .gitignore terraform.tfvars.example README.md; do
  if [ -f "$f" ] && [ -s "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ $f (missing or empty)"
  fi
done

# Check sample-app files  
for f in sample-app/app.py sample-app/requirements.txt sample-app/Dockerfile sample-app/Dockerfile.secure sample-app/buildspec.yml; do
  if [ -f "$f" ] && [ -s "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ $f (missing or empty)"
  fi
done

# Check scripts
for f in scripts/scan-image.sh scripts/test-deployment.sh; do
  if [ -f "$f" ] && [ -s "$f" ]; then
    echo "✅ $f"
  else
    echo "❌ $f (missing or empty)"
  fi
done
