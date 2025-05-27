


aws cloudformation package   --template-file vpn-stack/openvpn_template.yaml   --s3-bucket your-bucket   --output-template-file vpn-server-packaged.yaml

aws cloudformation deploy   --template-file vpn-server-packaged.yaml   --stack-name vpn-stack   --capabilities CAPABILITY_NAMED_IAM   --parameter-overrides KeyPairName=vpn-server-key S3BucketName=your-bucket