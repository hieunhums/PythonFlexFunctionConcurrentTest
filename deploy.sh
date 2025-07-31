#!/bin/bash

# Variables
RESOURCE_GROUP="myflexfunctions-rg"
LOCATION="eastasia"
STORAGE_ACCOUNT="myflexstorage$(date +%s)"
FUNCTION_APP_NAME="myflexfunction-$(date +%s)"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

# Create Function App with Flex Consumption plan
az functionapp create \
    --name $FUNCTION_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --storage-account $STORAGE_ACCOUNT \
    --flexconsumption-location $LOCATION \
    --runtime python \
    --runtime-version 3.11

echo "Function App: $FUNCTION_APP_NAME"
echo "Deploy with: func azure functionapp publish $FUNCTION_APP_NAME"

# Deploy the function app
echo "Deploying function app..."
func azure functionapp publish $FUNCTION_APP_NAME

# List functions and show URL
echo ""
echo "Deployment complete. Function endpoints:"
func azure functionapp list-functions $FUNCTION_APP_NAME --show-keys