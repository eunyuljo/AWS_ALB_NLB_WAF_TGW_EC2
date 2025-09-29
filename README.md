# Hub-Spoke AWS Architecture with ALB, NLB, and Transit Gateway

This Terraform configuration implements a Hub-Spoke architecture in AWS ap-northeast-2 region with the following components:

## Architecture Overview

```
External Client
    ↓
Internet Gateway (Central VPC)
    ↓
Internet-facing ALB (Public Subnet)
    ↓
Internal NLB (Private Subnet)
    ↓
Proxy Servers (Nginx - replacing WAF)
    ↓
Transit Gateway
    ↓
Spoke VPC Services (3-tier Architecture)
```

## Key Features

1. **Hub VPC** - Central connectivity with Internet Gateway
2. **Spoke VPCs** - No IGW, internet access via Transit Gateway through Hub
3. **3-tier Architecture** in each Spoke VPC:
   - Web Tier (Apache HTTP Server)
   - Application Tier (Java Application)
   - Database Tier (MariaDB)
4. **Load Balancing**:
   - Internet-facing ALB in Hub public subnets
   - Internal NLB in Hub private subnets
   - Internal ALB in each Spoke VPC
5. **Proxy Solution** - Nginx-based proxy replacing third-party WAF
6. **Transit Gateway** - Enables connectivity between Hub and Spoke VPCs
7. **AL2023 Instances** - All EC2 instances use Amazon Linux 2023

## Infrastructure Components

### Hub VPC (10.0.0.0/16)
- Public subnets for Internet-facing ALB
- Private subnets for Internal NLB and proxy instances
- NAT Gateways for outbound internet access
- Internet Gateway for inbound traffic

### Spoke VPCs (10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16)
- Web subnet (Apache servers)
- Application subnet (Java applications)
- Database subnet (MariaDB)
- Private subnet for Transit Gateway attachment

### Security Groups
- Proper tier-to-tier communication restrictions
- Least privilege access patterns
- Hub-to-Spoke connectivity via Transit Gateway

## Deployment Instructions

1. **Prerequisites**:
   - AWS CLI configured
   - Terraform >= 1.0 installed
   - EC2 Key Pair created in ap-northeast-2

2. **Configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your key pair name and other settings
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access**:
   - Use the ALB DNS name from outputs to access the application
   - Traffic flows through the proxy to spoke VPC services

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| aws_region | ap-northeast-2 | AWS region |
| project_name | hub-spoke-architecture | Project naming prefix |
| hub_vpc_cidr | 10.0.0.0/16 | Hub VPC CIDR |
| spoke_vpc_cidrs | [10.1.0.0/16, 10.2.0.0/16, 10.3.0.0/16] | Spoke VPC CIDRs |
| instance_type | t3.medium | EC2 instance type |
| key_name | "" | EC2 Key Pair name (required) |

## Outputs

- ALB and NLB DNS names
- VPC and Transit Gateway IDs
- Instance IDs for all tiers
- Auto Scaling Group name for proxy instances

## Security Features

- No direct internet access from Spoke VPCs
- Traffic flows through centralized proxy
- Proper security group isolation
- 3-tier architecture separation
- Encrypted communication between tiers

## Monitoring and Scaling

- Auto Scaling Group for proxy instances (2-6 instances)
- Health checks for all load balancers
- CloudWatch integration (via AWS provider)

## Clean Up

```bash
terraform destroy
```

**Note**: Ensure you have the correct AWS credentials and permissions before deployment.