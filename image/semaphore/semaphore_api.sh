#!/bin/bash

# Set up
BASE_URL="http://localhost:3000/api"
USERNAME="ddadmin"
PASSWORD="DigitalData2025!"
SSH_KEY_ID=1

# Project
PROJECT_NAME="Client"

# Repo
REPO_NAME="Client"
GIT_URL="/Navy-VRAM"
GIT_BRANCH=""

# Inventory
INVENTORY_NAME="AnsibleInventory"
INVENTORY_FILE_PATH="/IL5/ansible/inventory.ini"

# Tasks Template
TASK1_NAME="Azure Login"
PLAYBOOK_1="az_login.sh"
TASK2_NAME="RHEL Playbook"
PLAYBOOK_2="/IL5/ansible/rhel9-setup-playbook.yml"
TASK3_NAME="STIG Fixes"
PLAYBOOK_3="/IL5/ansible/stig_fixes_playbook.sh"
TASK4_NAME="STIG Partitions"
PLAYBOOK_4="/IL5/ansible/stig_partitions.sh"
TASK5_NAME="Airgap"
PLAYBOOK_5="airgap.sh"

# Login
echo "Logging in..."
LOGIN_RESPONSE=$(curl -s -c /tmp/semaphore-cookie POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"auth": "'${USERNAME}'", "password": "'${PASSWORD}'"}' \
  "$BASE_URL/auth/login")

if [[ ! -s /tmp/semaphore-cookie ]]; then
  echo "Login failed: $LOGIN_RESPONSE"
fi

echo "Login successful"

# Create Token
echo "Creating token..."
TOKEN_RESPONSE=$(curl -s -b /tmp/semaphore-cookie POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"name": "AutomationToken"}' \
  "$BASE_URL/user/tokens")

echo "Token creation response: $TOKEN_RESPONSE"

USER_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.id')

if [[ -z "$USER_TOKEN" || "$USER_TOKEN" == "null" ]]; then
  echo "Failed to create token."
fi

echo "Token created: $USER_TOKEN"

# Create Project
echo "Creating project..."
PROJECT_RESPONSE=$(curl -s POST \
  "$BASE_URL/projects" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'${PROJECT_NAME}'"
  }')

PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.id')

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  echo "Failed to create project."
fi

echo "Project created with ID: $PROJECT_ID"

# Add Repo
echo "Adding repository..."
ADD_REPO_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/repositories" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${REPO_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "git_url": "'"${GIT_URL}"'",
    "git_branch": "'"${GIT_BRANCH}"'",
    "ssh_key_id": '"${SSH_KEY_ID}"'
  }')

if [[ "$ADD_REPO_RESPONSE" == *"error"* ]]; then
  echo "Failed to add repository: $ADD_REPO_RESPONSE"
fi

GET_REPO_RESPONSE=$(curl -s GET \
  "$BASE_URL/project/$PROJECT_ID/repositories" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $USER_TOKEN")

REPO_ID=$(echo "$GET_REPO_RESPONSE" | jq -r '.[0].id')

echo "Repository added successfully ID: $REPO_ID"

# Add Inventory
echo "Adding inventory..."
ADD_INVENTORY_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/inventory" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${INVENTORY_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "repository_id": '"${REPO_ID}"',
    "ssh_key_id": '"${SSH_KEY_ID}"',
    "type": "file",
    "inventory": "'"${INVENTORY_FILE_PATH}"'"
  }')

GET_INVENTORY_RESPONSE=$(curl -s GET \
  "$BASE_URL/project/$PROJECT_ID/inventory" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $USER_TOKEN")

INVENTORY_ID=$(echo "$GET_INVENTORY_RESPONSE" | jq -r '.[0].id')

if [[ "$ADD_INVENTORY_RESPONSE" == *"error"* ]]; then
  echo "Failed to add inventory: $ADD_INVENTORY_RESPONSE"
fi

echo "Inventory added successfully."


# Add Task Template
echo "Adding Task 1..."
ADD_TASK1_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/templates" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${TASK1_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "repository_id": '"${REPO_ID}"',
    "playbook": "'"${PLAYBOOK_1}"'",
    "environment_id": 1,
    "description": "azure login",
    "app": "bash",
    "type": "",
    "autorun": false
  }')

if [[ "$ADD_TASK1_RESPONSE" == *"error"* ]]; then
  echo "Failed to add task $ADD_TASK1_RESPONSE"
fi

echo "Adding Task 2..."
ADD_TASK2_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/templates" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${TASK2_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "repository_id": '"${REPO_ID}"',
    "inventory_id": '"${INVENTORY_ID}"',
    "playbook": "'"${PLAYBOOK_2}"'",
    "environment_id": 1,
    "description": "RHEL Playbook",
    "app": "ansible",
    "type": "",
    "autorun": false
  }')

if [[ "$ADD_TASK2_RESPONSE" == *"error"* ]]; then
  echo "Failed to add task: $ADD_TASK2_RESPONSE"
fi

echo "Adding Task 3..."
ADD_TASK3_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/templates" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${TASK3_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "repository_id": '"${REPO_ID}"',
    "playbook": "'"${PLAYBOOK_3}"'",
    "environment_id": 1,
    "description": "stig fixes",
    "app": "bash",
    "type": "",
    "autorun": false
  }')

if [[ "$ADD_TASK3_RESPONSE" == *"error"* ]]; then
  echo "Failed to add task $ADD_TASK3_RESPONSE"
fi

echo "Adding Task 4..."
ADD_TASK1_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/templates" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${TASK4_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "repository_id": '"${REPO_ID}"',
    "playbook": "'"${PLAYBOOK_4}"'",
    "environment_id": 1,
    "description": "stig paritions",
    "app": "bash",
    "type": "",
    "autorun": false
  }')

if [[ "$ADD_TASK4_RESPONSE" == *"error"* ]]; then
  echo "Failed to add task $ADD_TASK4_RESPONSE"
fi

echo "Adding Task 5..."
ADD_TASK1_RESPONSE=$(curl -s POST \
  "$BASE_URL/project/$PROJECT_ID/templates" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "'"${TASK5_NAME}"'",
    "project_id": '"${PROJECT_ID}"',
    "repository_id": '"${REPO_ID}"',
    "playbook": "'"${PLAYBOOK_5}"'",
    "environment_id": 1,
    "description": "airgap",
    "app": "bash",
    "type": "",
    "autorun": false
  }')

if [[ "$ADD_TASK5_RESPONSE" == *"error"* ]]; then
  echo "Failed to add task $ADD_TASK5_RESPONSE"
fi
