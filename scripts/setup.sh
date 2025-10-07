#!/bin/bash
# scripts/create-resource-group.sh

RESOURCE_GROUP_NAME="rg-monapp-infra"
LOCATION="francecentral"

echo "📦 Création du Resource Group: $RESOURCE_GROUP_NAME"

az group create \
  --name $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --tags "Environment=Dev" "Project=MonApp"

echo "✅ Resource Group créé: $RESOURCE_GROUP_NAME"
