# AWS and Terraform Mini Project

This project provisions a two-tier AWS environment using Terraform and deploys containerized frontend and backend applications.

## Architecture

```text
Internet
   |
Internet Gateway
   |
Public Subnet
   |
Frontend EC2
   | TCP 5000
Private Subnet
   |
Backend EC2
   |
NAT Gateway
   |
Internet
```

## Infrastructure

Terraform creates:

- One VPC
- One public subnet
- One private subnet
- Internet Gateway
- NAT Gateway and Elastic IP
- Public and private route tables
- Frontend and backend security groups
- Frontend EC2 instance
- Backend EC2 instance
- AWS EC2 Key Pair

## Security

- HTTP port 80 is open on the frontend.
- SSH port 22 on the frontend is restricted to the administrator IP.
- The backend has no public IPv4 address.
- Backend application port 5000 accepts traffic only from the frontend security group.
- Backend SSH access is possible only through the frontend jump host.

## Applications

### Frontend

- Runs inside an Nginx container.
- Listens on port 80.
- Proxies `/api/` requests to the private backend.

### Backend

- Runs a Flask API inside a Docker container.
- Listens on port 5000.
- Provides `/` and `/health` endpoints.

## Project Structure

```text
Terraform-01/
├── Terraform-iac/
│   ├── main.tf
│   ├── outputs.tf
│   ├── frontend-user-data.sh
│   └── backend-user-data.sh
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── backend/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── .gitignore
└── README.md
```

## Prerequisites

Before using this project, install and configure:

- Terraform
- AWS CLI
- Git
- An AWS account
- AWS credentials with the required permissions
- An SSH public and private key pair

Verify the installed tools:

```bash
terraform version
aws --version
git --version
```

Verify access to AWS:

```bash
aws sts get-caller-identity
```

## Terraform Usage

Move into the Terraform directory:

```bash
cd Terraform-iac
```

Initialize Terraform:

```bash
terraform init
```

Check formatting:

```bash
terraform fmt -check
```

Validate the configuration:

```bash
terraform validate
```

Review the execution plan:

```bash
terraform plan
```

Create the infrastructure only after reviewing the plan:

```bash
terraform apply
```

Do not approve an apply operation if the plan contains unexpected changes or resource destruction.

## Terraform Outputs

Display the infrastructure outputs:

```bash
terraform output
```

Terraform displays:

- Frontend instance ID
- Frontend public IPv4 address
- Frontend URL
- Backend instance ID
- Backend private IPv4 address

## Frontend Access

Display the frontend URL:

```bash
terraform output -raw frontend_url
```

Open the returned URL in a browser.

The frontend sends requests to:

```text
/api/health
```

Nginx proxies those requests to the backend server inside the private subnet.

## Frontend SSH Access

Get the frontend public IP:

```bash
terraform output -raw frontend_public_ip
```

Connect using the private SSH key:

```bash
ssh -i ~/.ssh/aws-terraform-key ec2-user@FRONTEND_PUBLIC_IP
```

Replace `FRONTEND_PUBLIC_IP` with the value returned by Terraform.

## Backend SSH Access

The backend does not have a public IP address. Access it through the frontend jump host.

Get the required addresses:

```bash
terraform output -raw frontend_public_ip
terraform output -raw backend_private_ip
```

Connect using a proxy command:

```bash
ssh \
  -i ~/.ssh/aws-terraform-key \
  -o 'ProxyCommand=ssh -i ~/.ssh/aws-terraform-key -W %h:%p ec2-user@FRONTEND_PUBLIC_IP' \
  ec2-user@BACKEND_PRIVATE_IP
```

Replace `FRONTEND_PUBLIC_IP` and `BACKEND_PRIVATE_IP` with the Terraform output values.

## Docker Verification

On either EC2 instance, verify Docker:

```bash
docker --version
sudo systemctl is-active docker
```

List running containers:

```bash
docker ps
```

## Backend Health Check

From the frontend server, test the private backend:

```bash
curl http://BACKEND_PRIVATE_IP:5000/health
```

Expected response:

```json
{"service":"backend","status":"ok"}
```

## Cost Warning

The following resources may incur AWS charges:

- NAT Gateway
- Elastic IP and public IPv4 addresses
- Frontend EC2 instance
- Backend EC2 instance
- Network data transfer

Do not leave the environment running when it is no longer needed.

## Cleanup

Review the destruction plan:

```bash
terraform plan -destroy
```

If the plan contains only the expected project resources, destroy the environment:

```bash
terraform destroy
```

Confirm destruction only after carefully reviewing the resource list.

Afterward, verify that Terraform no longer manages resources:

```bash
terraform state list
```

## Important Security Notes

- Never commit Terraform state files.
- Never commit private SSH keys.
- Never commit AWS credentials.
- Keep SSH access restricted to a trusted `/32` IP address.
- Do not expose the backend directly to the internet.
- Review every Terraform plan before applying it.