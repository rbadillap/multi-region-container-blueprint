#!/bin/bash

# Terrawork Setup Script
# This script helps set up the initial infrastructure for state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output with timestamp
log_message() {
    local level=$1
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] ${level}: $*"
}

print_status() {
    log_message "INFO" "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    log_message "WARN" "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    log_message "ERROR" "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate parameters
validate_parameters() {
    local account=$1
    local env=$2
    local region=$3
    
    print_status "Validating parameters..."
    
    # Validate account name (lowercase letters, numbers, and hyphens only)
    if [[ ! "$account" =~ ^[a-z0-9-]+$ ]]; then
        print_error "Account name must contain only lowercase letters, numbers, and hyphens"
        exit 1
    fi
    
    # Validate AWS region
    if ! aws ec2 describe-regions --region-names "$region" >/dev/null 2>&1; then
        print_error "Invalid AWS region: $region"
        exit 1
    fi
    
    print_status "Parameters validation passed."
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

# Function to create S3 bucket with enhanced security
create_s3_bucket() {
    local account=$1
    local env=$2
    local region=$3
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local bucket_name="terrawork-${account_id}-${account}-${env}-${region}"
    
    print_status "Creating S3 bucket: ${bucket_name}"
    
    # Check if bucket already exists
    if aws s3 ls "s3://${bucket_name}" 2>&1 | grep -q 'NoSuchBucket'; then
        # Create bucket
        if ! aws s3 mb "s3://${bucket_name}" --region "${region}"; then
            print_error "Failed to create S3 bucket ${bucket_name}"
            return 1
        fi
        
        # Enable versioning
        if ! aws s3api put-bucket-versioning \
            --bucket "${bucket_name}" \
            --versioning-configuration Status=Enabled; then
            print_error "Failed to enable versioning on bucket ${bucket_name}"
            return 1
        fi
        
        # Enable server-side encryption
        if ! aws s3api put-bucket-encryption \
            --bucket "${bucket_name}" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'; then
            print_error "Failed to enable encryption on bucket ${bucket_name}"
            return 1
        fi
        
        # Block public access
        if ! aws s3api put-public-access-block \
            --bucket "${bucket_name}" \
            --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true; then
            print_error "Failed to block public access on bucket ${bucket_name}"
            return 1
        fi
        
        # Add tags for resource management
        if ! aws s3api put-bucket-tagging \
            --bucket "${bucket_name}" \
            --tagging "TagSet=[{Key=Project,Value=Terrawork},{Key=Environment,Value=${env}},{Key=Account,Value=${account}}]"; then
            print_warning "Failed to add tags to bucket ${bucket_name}"
        fi
        
        print_status "S3 bucket created successfully with security configurations."
    else
        print_warning "S3 bucket ${bucket_name} already exists."
    fi
}

# Function to create DynamoDB table with enhanced configuration
create_dynamodb_table() {
    local account=$1
    local env=$2
    local region=$3
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local table_name="terrawork-locks-${account_id}-${account}-${env}-${region}"
    
    print_status "Creating DynamoDB table: ${table_name}"
    
    if aws dynamodb describe-table --table-name "${table_name}" --region "${region}" 2>&1 | grep -q 'ResourceNotFoundException'; then
        if ! aws dynamodb create-table \
            --table-name "${table_name}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${region}"; then
            print_error "Failed to create DynamoDB table ${table_name}"
            return 1
        fi
        
        # Wait for table to be created
        print_status "Waiting for DynamoDB table to be created..."
        if ! aws dynamodb wait table-exists --table-name "${table_name}" --region "${region}"; then
            print_error "Failed to wait for DynamoDB table creation"
            return 1
        fi
        
        # Add tags for resource management
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        local table_arn="arn:aws:dynamodb:${region}:${account_id}:table/${table_name}"
        
        if ! aws dynamodb tag-resource \
            --resource-arn "${table_arn}" \
            --tags "[{Key=Project,Value=Terrawork},{Key=Environment,Value=${env}},{Key=Account,Value=${account}}]"; then
            print_warning "Failed to add tags to DynamoDB table ${table_name}"
        fi
        
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
    
    # Get and display AWS account information
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local user_arn=$(aws sts get-caller-identity --query Arn --output text)
    print_status "AWS credentials are valid."
    print_status "Account ID: ${account_id}"
    print_status "User ARN: ${user_arn}"
}

# Main function
main() {
    local account=${1:-"acme"}
    local env=${2:-"dev"}
    local region=${3:-"us-east-1"}
    
    print_status "Starting Terrawork setup..."
    print_status "Account: ${account}"
    print_status "Environment: ${env}"
    print_status "Region: ${region}"
    echo
    
    # Validate parameters
    validate_parameters "${account}" "${env}" "${region}"
    echo
    
    # Check prerequisites
    check_prerequisites
    echo
    
    # Validate AWS credentials
    validate_aws_credentials
    echo
    
    # Create infrastructure
    if ! create_s3_bucket "${account}" "${env}" "${region}"; then
        print_error "Failed to create S3 bucket. Exiting."
        exit 1
    fi
    echo
    
    if ! create_dynamodb_table "${account}" "${env}" "${region}"; then
        print_error "Failed to create DynamoDB table. Exiting."
        exit 1
    fi
    echo
    
    print_status "Setup completed successfully!"
    print_status "You can now run Terragrunt commands to deploy your infrastructure."
    echo
    print_status "Example commands:"
    echo "  cd accounts/${account}/${env}/${region}/networking"
    echo "  terragrunt init"
    echo "  terragrunt plan"
    echo "  terragrunt apply"
}

# Show usage
usage() {
    echo "Usage: $0 [account] [environment] [region]"
    echo "  account:     Account name (default: acme)"
    echo "  environment: Environment name (default: dev)"
    echo "  region:      AWS region (default: us-east-1)"
    echo
    echo "Example: $0 acme prod eu-west-1"
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@" 