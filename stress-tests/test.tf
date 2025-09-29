terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "null" {}
provider "local" {}

variable "resource_count" {
  description = "How many dummy resources to create"
  default     = 500
}

resource "null_resource" "stress" {
  count = var.resource_count

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo Null resource ${count.index} created at $(date)"
  }
}

resource "local_file" "dummy_files" {
  count    = var.resource_count
  content  = "This is test file #${count.index}"
  filename = "${path.module}/output/file_${count.index}.txt"
}