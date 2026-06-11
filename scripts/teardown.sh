#!/usr/bin/env bash
# Destroys all Terraform-managed AWS resources.
# Safe to re-run — Terraform handles idempotency.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

echo "==> Destroying all Terraform-managed resources..."
if [ -f "${TERRAFORM_DIR}/terraform.tfstate" ] || [ -d "${TERRAFORM_DIR}/.terraform" ]; then
  cd "$TERRAFORM_DIR"
  terraform destroy -auto-approve
  cd - >/dev/null
else
  echo "     no Terraform state found, skipping"
fi

echo ""
echo "==> Cleanup complete. Ready to run:"
echo "    cd terraform && terraform apply"
