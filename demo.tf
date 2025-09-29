terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "local" {}

variable "file_content" {
  description = "The content to write to the local file"
  type        = string
  default     = <<EOT
This is an example file created by Terraform.
You can customize its content.
EOT
}

# Define a local file
resource "local_file" "example" {
  filename = "${path.module}/example.txt"
  content  = var.file_content
}

# Output the file path
output "file_path" {
  value = local_file.example.filename
}
