# OpenVPN Server on AWS EC2 - Automated Deployment

![OpenVPN Logo](https://openvpn.net/wp-content/uploads/2013/04/openvpn_logo-300x95.png)

## 📝 Description

This project automates the deployment of a secure OpenVPN server on AWS EC2 using CloudFormation, pre-configured for 5 users with self-signed certificates. The solution uses cost-effective instances (t3.nano/micro) with Ubuntu Server.

## ✨ Key Features

- ✅ Automated CloudFormation deployment
- ✅ Secure TLS certificate configuration
- ✅ 5 pre-configured client profiles
- ✅ Full-tunnel traffic routing
- ✅ Optional post-configuration script
- ✅ Estimated cost: ~$3.50-$7.00/month


## 🚀 Quick Deployment

### Prerequisites
- Configured AWS CLI
- Existing EC2 key pair

### Deployment Steps:

1. Deploy CloudFormation stack:
```bash
aws cloudformation create-stack \
  --stack-name OpenVPNServer \
  --template-body file://cloudformation/openvpn-template.yaml \
  --parameters ParameterKey=KeyPairName,ParameterValue=YOUR_KEY_PAIR
```