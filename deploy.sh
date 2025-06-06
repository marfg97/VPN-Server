
aws cloudformation deploy \
  --template-file vpn-stack/openvpn_template.yaml \
  --stack-name vpn-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    KeyPairName=your_key \
    S3BucketName=your_bucket \
    ScriptKey=vpn/scripts/vpn_config.sh
