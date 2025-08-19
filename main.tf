terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  owner = "Practical-DevOps-GitHub"
  token = var.github_token
}

variable "github_token" {
  type        = string
  description = "GitHub Personal Access Token"
  sensitive   = true
}

data "github_repository" "existing" {
  full_name = "Practical-DevOps-GitHub/github-terraform-task-YanaBoyko1"
}

# Add collaborator
resource "github_repository_collaborator" "softservedata" {
  repository = data.github_repository.existing.name
  username   = "softservedata"
  permission = "push"
}

# Create develop branch
resource "github_branch" "develop" {
  repository    = data.github_repository.existing.name
  branch        = "develop"
  source_branch = "main"
}

# Set develop as default branch
resource "github_branch_default" "default" {
  repository = data.github_repository.existing.name
  branch     = "develop"
  depends_on = [github_branch.develop]
}

# Create CODEOWNERS file
resource "github_repository_file" "codeowners" {
  repository          = data.github_repository.existing.name
  branch              = "main"
  file                = "CODEOWNERS"
  content             = "* @softservedata"
  commit_message      = "Add CODEOWNERS file"
  commit_author       = "Yana Boyko"
  commit_email        = "ivannaboyko1@gmail.com"
  overwrite_on_create = true
}

# Protect develop branch
resource "github_branch_protection" "develop" {
  repository_id = data.github_repository.existing.node_id
  pattern       = "develop"

  allows_deletions          = false
  allows_force_pushes       = false
  required_linear_history   = true
  require_conversation_resolution = true

  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = false
    required_approving_review_count = 2
  }

  restrict_pushes {
    push_allowances = []
  }
}

# Protect main branch
resource "github_branch_protection" "main" {
  repository_id = data.github_repository.existing.node_id
  pattern       = "main"

  allows_deletions          = false
  allows_force_pushes       = false
  required_linear_history   = true
  require_conversation_resolution = true

  required_pull_request_reviews {
    dismiss_stale_reviews      = true
    require_code_owner_reviews = true
  }

  restrict_pushes {
    push_allowances = []
  }
}

# Create Pull Request template
resource "github_repository_file" "pull_request_template" {
  repository          = data.github_repository.existing.name
  branch              = "main"
  file                = ".github/pull_request_template.md"
  content             = <<-EOT
# Describe your changes

## Issue ticket number and link

## Checklist before requesting a review
- [ ] I have performed a self-review of my code
- [ ] If it is a core feature, I have added thorough tests
- [ ] Do we need to implement analytics?
- [ ] Will this be part of a product update? If yes, please write one phrase about this update
EOT
  commit_message      = "docs: add pull request template"
  commit_author       = "Yana Boyko"
  commit_email        = "ivannaboyko1@gmail.com"
  overwrite_on_create = true
}

# Generate SSH key
resource "tls_private_key" "deploy_key" {
  algorithm = "ED25519"
}

# Add deploy key
resource "github_repository_deploy_key" "deploy_key" {
  title      = "DEPLOY_KEY"
  repository = data.github_repository.existing.name
  key        = tls_private_key.deploy_key.public_key_openssh
  read_only  = false
}

# Add Discord webhook
resource "github_repository_webhook" "discord_pr_notifications" {
  repository = data.github_repository.existing.name

  configuration {
    url          = "https://discord.com/api/webhooks/1407354858477977721/wBDKskCgqD74r1JyLF7uKN-D-p6IBT1gRKHeKDq6JM1AdLzMo_JPVYR64DTyFAVxJuGm"
    content_type = "json"
    insecure_ssl = false
  }

  events = ["pull_request"]
}

# Add PAT secret
resource "github_actions_secret" "pat_secret" {
  repository      = data.github_repository.existing.name
  secret_name     = "PAT"
  plaintext_value = var.github_token
}

# Output private key for saving
output "deploy_private_key" {
  value       = tls_private_key.deploy_key.private_key_openssh
  sensitive   = true
  description = "Private key for DEPLOY_KEY - save this securely!"
}





