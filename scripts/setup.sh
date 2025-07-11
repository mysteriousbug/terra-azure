#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="webapp"
LOCATION="East US"
TERRAFORM_STATE_RG="terraform-state-rg"
TERRAFORM_STATE_SA="terraformstate$(date +%s)"
TERRAFORM_STATE_CONTAINER="tfstate"

echo -e "${GREEN}🚀 Starting Azure Terraform Jenkins Setup${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Please login first.${NC}"
    az login
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo -e "${GREEN}✅ Using subscription: $SUBSCRIPTION_ID${NC}"

# Create resource group for Terraform state
echo -e "${GREEN}📦 Creating resource group for Terraform state...${NC}"
az group create \
    --name $TERRAFORM_STATE_RG \
    --location "$LOCATION" \
    --output none

# Create storage account for Terraform state
echo -e "${GREEN}💾 Creating storage account for Terraform state...${NC}"
az storage account create \
    --name $TERRAFORM_STATE_SA \
    --resource-group $TERRAFORM_STATE_RG \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --encryption-services blob \
    --output none

# Create container for Terraform state
echo -e "${GREEN}📁 Creating container for Terraform state...${NC}"
az storage container create \
    --name $TERRAFORM_STATE_CONTAINER \
    --account-name $TERRAFORM_STATE_SA \
    --output none

# Create service principal for Terraform
echo -e "${GREEN}🔑 Creating service principal for Terraform...${NC}"
SP_JSON=$(az ad sp create-for-rbac \
    --name "terraform-${PROJECT_NAME}-sp" \
    --role "Contributor" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth)

CLIENT_ID=$(echo $SP_JSON | jq -r '.clientId')
CLIENT_SECRET=$(echo $SP_JSON | jq -r '.clientSecret')
TENANT_ID=$(echo $SP_JSON | jq -r '.tenantId')

# Create .env file for local development
echo -e "${GREEN}📝 Creating .env file for local development...${NC}"
cat > .env << EOF
# Azure credentials
export ARM_CLIENT_ID="$CLIENT_ID"
export ARM_CLIENT_SECRET="$CLIENT_SECRET"
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export ARM_TENANT_ID="$TENANT_ID"

# Terraform backend configuration
export TF_STATE_RESOURCE_GROUP="$TERRAFORM_STATE_RG"
export TF_STATE_STORAGE_ACCOUNT="$TERRAFORM_STATE_SA"
export TF_STATE_CONTAINER="$TERRAFORM_STATE_CONTAINER"

# Project configuration
export TF_VAR_project_name="$PROJECT_NAME"
export TF_VAR_location="$LOCATION"
export TF_VAR_owner="DevOps Team"
EOF

echo -e "${GREEN}✅ .env file created. Source it with: source .env${NC}"

# Create Jenkins credentials script
echo -e "${GREEN}📝 Creating Jenkins credentials setup script...${NC}"
cat > scripts/jenkins-credentials.sh << 'EOF'
#!/bin/bash
# Jenkins Credentials Setup Script
# Run this script to add credentials to Jenkins

JENKINS_URL="http://localhost:8080"  # Update with your Jenkins URL
JENKINS_USER="admin"                 # Update with your Jenkins username
JENKINS_PASSWORD="admin"             # Update with your Jenkins password

# Add Azure credentials
curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
  --user "$JENKINS_USER:$JENKINS_PASSWORD" \
  --data-urlencode 'json={
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "azure-client-id",
      "secret": "'$ARM_CLIENT_ID'",
      "description": "Azure Client ID",
      "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
    }
  }'