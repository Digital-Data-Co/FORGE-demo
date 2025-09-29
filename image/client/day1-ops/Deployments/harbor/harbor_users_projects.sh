#!/bin/bash
set -e

HARBOR_API="https://harbor.local/api/v2.0"
AUTH="admin:SuperSecretPass123"
PROJECT="k8s"

create_user() {
  local username="$1"
  local realname="$2"
  local password
  password=$(openssl rand -base64 14)

  curl -sk -u $AUTH -X POST "$HARBOR_API/users" -H "Content-Type: application/json" -d @- <<EOF
{
  "username": "$username",
  "realname": "$realname",
  "email": "",
  "password": "$password"
}
EOF

  echo "Created user $username with password: $password"
}

add_to_project() {
  local username="$1"
  uid=$(curl -sk -u $AUTH "$HARBOR_API/users/search?q=$username" | jq '.[0].user_id')

  curl -sk -u $AUTH -X POST "$HARBOR_API/projects/$PROJECT/members" -H "Content-Type: application/json" -d @- <<EOF
{
  "role_id": 2,
  "member_user": {
    "user_id": $uid
  }
}
EOF
}

create_user "dnelson" "Dave Nelson"
add_to_project "dnelson"

create_user "badamek" "Brandon Adamek"
add_to_project "badamek"
