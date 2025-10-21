# Forge Demo - Terramate Stack Configuration
# This demonstrates Terramate orchestration with cross-project dependencies and drift detection

terramate {
  config {
    # Terramate configuration
    experiments = [
      "scripts",
      "tmgen"
    ]
  }
}

stack {
  name        = "networking-stack"
  description = "Core networking infrastructure with VPC, subnets, and security groups"
  id          = "networking"
  
  # Tags for Forge integration
  tags = [
    "environment:production",
    "forge:managed",
    "compliance:stig",
    "stack:networking"
  ]
  
  # Define after dependencies (this stack must run before others)
  after = []
  
  # Define before dependencies (these stacks depend on this one)
  before = [
    "/stack-2",  # Compute stack depends on networking
    "/stack-3"   # Database stack depends on networking
  ]
}

# Generate Terraform variables from Terramate
generate_hcl "_terramate_generated.tf" {
  content {
    # Inject Forge metadata
    locals {
      forge_project_id = tm_try(global.forge_project_id, "demo-project")
      forge_stack_id   = stack.id
      forge_stack_name = stack.name
      environment      = tm_try(global.environment, "production")
      
      # Tags to apply to all resources
      common_tags = {
        ManagedBy     = "Forge"
        Environment   = local.environment
        StackID       = local.forge_stack_id
        StackName     = local.forge_stack_name
        ProjectID     = local.forge_project_id
        STIGCompliant = "true"
      }
    }
  }
}

# Drift detection configuration for Forge
globals {
  drift_detection = {
    enabled            = true
    schedule           = "0 */6 * * *"  # Every 6 hours
    auto_remediate     = false
    notification_email = "ops@example.com"
  }
}

