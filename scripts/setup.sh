#!/bin/bash

# MRCB Setup Script
# This script helps set up the initial infrastructure for state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists aws; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists terragrunt; then
        print_error "Terragrunt is not installed. Please install it first."
        exit 1
    fi
    
    print_status "All prerequisites are installed."
}

# Function to create S3 bucket
create_s3_bucket() {
    local client=$1
    local env=$2
    local region=$3
    local bucket_name="mrcb-terraform-state-${client}-${env}"
    
    print_status "Creating S3 bucket: ${bucket_name}"
    
    if aws s3 ls "s3://${bucket_name}" 2>&1 | grep -q 'NoSuchBucket'; then
        aws s3 mb "s3://${bucket_name}" --region "${region}"
        aws s3api put-bucket-versioning \
            --bucket "${bucket_name}" \
            --versioning-configuration Status=Enabled
        print_status "S3 bucket created successfully."
    else
        print_warning "S3 bucket ${bucket_name} already exists."
    fi
}

# Function to create DynamoDB table
create_dynamodb_table() {
    local client=$1
    local env=$2
    local region=$3
    local table_name="mrcb-terraform-locks-${client}-${env}"
    
    print_status "Creating DynamoDB table: ${table_name}"
    
    if aws dynamodb describe-table --table-name "${table_name}" --region "${region}" 2>&1 | grep -q 'ResourceNotFoundException'; then
        aws dynamodb create-table \
            --table-name "${table_name}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${region}"
        
        # Wait for table to be created
        print_status "Waiting for DynamoDB table to be created..."
        aws dynamodb wait table-exists --table-name "${table_name}" --region "${region}"
        print_status "DynamoDB table created successfully."
    else
        print_warning "DynamoDB table ${table_name} already exists."
    fi
}

# Function to validate AWS credentials
validate_aws_credentials() {
    print_status "Validating AWS credentials..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials are not configured or invalid."
        print_error "Please run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    print_status "AWS credentials are valid."
}

# Main function
main() {
    local client=${1:-"client-a"}
    local env=${2:-"dev"}
    local region=${3:-"us-east-1"}
    
    print_status "Starting MRCB setup..."
    print_status "Client: ${client}"
    print_status "Environment: ${env}"
    print_status "Region: ${region}"
    echo
    
    # Check prerequisites
    check_prerequisites
    echo
    
    # Validate AWS credentials
    validate_aws_credentials
    echo
    
    # Create infrastructure
    create_s3_bucket "${client}" "${env}" "${region}"
    echo
    
    create_dynamodb_table "${client}" "${env}" "${region}"
    echo
    
    print_status "Setup completed successfully!"
    print_status "You can now run Terragrunt commands to deploy your infrastructure."
    echo
    print_status "Example commands:"
    echo "  cd live/${client}/${env}/${region}/networking"
    echo "  terragrunt init"
    echo "  terragrunt plan"
    echo "  terragrunt apply"
}

# Show usage
usage() {
    echo "Usage: $0 [client] [environment] [region]"
    echo "  client:      Client name (default: client-a)"
    echo "  environment: Environment name (default: dev)"
    echo "  region:      AWS region (default: us-east-1)"
    echo
    echo "Example: $0 client-b prod eu-west-1"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@" 