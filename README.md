# Terraform IAM Playground

I wrote this for us to play around with in class to give a more practical example of IAM Roles in AWS.

Three TF_VAR exports need to be made:

* `export TF_VAR_bucket_name=YOURBUCKETNAME`
* `export TF_VAR_profile_name=YOURPROFILENAME` the default is "default" but incase you have multiple profiles set up use this.
* `export TF_VAR_ssh_key_pair=$(cat ~/.ssh/id_rsa.pub)` - you must have an existing SSH key for this command to work, if not you can modify the terraform to reflect an existing AWS PEM key pair.
* `export TF_VAR_db_username=YOURDBUSERNAME`
## Deployment Steps

1. `terraform init`
2. `terraform plan`
3. `terraform apply -auto-approve`

Terraform will output a bucket name and an EC2 public IP address. SSH to the public IP.

* `ssh ec2-user@$YOURPUBLICIP`

Can you see the bucket when you run the command `aws s3 ls`?
Can you download the flag.txt in the bucket root?
Can you upload a new file to the bucket using `aws s3 cp file.txt s3://YOURBUCKETNAME`?

## Connect to RDS

* `export RDS_TOKEN=$(aws rds generate-db-auth-token --hostname $YOUR_RDS_ENDPOINT --port 3306 --username $YOUR_USERNAME)`
* `wget https://s3.amazonaws.com/rds-downloads/rds-ca-2019-root.pem`