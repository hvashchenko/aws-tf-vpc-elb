output "bucket_ids" {
    description = "bucket_id"
    value       = "${aws_s3_bucket.examplebucket.*.id}"
}
output "public_ip_1" {
  value       = "${aws_instance.testInstance2.public_ip}"
  description = "Public IP of the instance (or EIP)"
}
output "public_ip_2" {             
  value       = "${aws_instance.testInstance1.public_ip}"
  description = "Public IP of the instance (or EIP)"
}
output "lb_address" {
  value = "${aws_elb.bar.dns_name}"
}
