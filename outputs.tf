output "instance_ip_addr" {
  value = aws_instance.ec2_instance.public_ip
}


output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.id
}

output "rds_instance_ipv4" {
  value = aws_db_instance.mariadb_instance.endpoint
}