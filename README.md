# Infrastructure as Code Demo using Terraform and AWS

## Overview
This demo is based on the awesome resource below which walks through a simple Terraform "Hello world!" example.
https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180

In the example above, you create a simple web server running in AWS using Terraform. Then you expand by creating an autoscaling group with an elastic load balancer front end (technically we are deploying a classic load balancer for simplicity). The example contained in this repository deploys the autoscaling group with some with some tweaks. I updated some details compared to the original such as Terraform resource names, AWS region names, etc. to help absorb concepts.

## Installation and Setup
* The blog shown in the `Overview` section walks through all of the required installation including how to install the Terraform binary and how to setup a simple IAM account using the AWS free tier.

* I'm using Atom as my IDE with the `language-terraform` package to help with syntax highlighting and the typical bells and whistles. Definitely worth it!
https://atom.io/packages/language-terraform

* I'm using this .gitignore file to keep any Terraform artifacts out of the repository.
https://github.com/github/gitignore/blob/master/Terraform.gitignore

* If you want to change the region you deploy to, that's cool. Just make sure to update the AMI ID. This is using Ubuntu 18.04 LTS; same as the blog.
https://cloud-images.ubuntu.com/locator/ec2/

## Running
* Once you complete `Installation and Setup` always remember to first set the AWS authentication environment variables in any new shell you use to run the code.
```bash
export AWS_SECRET_ACCESS_KEY=<YOUR-KEY>
export AWS_ACCESS_KEY_ID=<YOUR-KEY-ID>
```

* As mentioned in the blog, first run `terraform init` to retrieve the required provider code (aws) and save it to a local `.terraform` directory.

* To test drive what changes will occur:

```bash
$ terraform plan
var.server_port
  The port the server will use for HTTP requests

  Enter a value: 8080

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

data.aws_availability_zones.all: Refreshing state...

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

.
.
.
```

* To deploy the application, you can let Terraform query you for the variables defined in the code, or you can pass the variables explicitly:

```bash
$ terraform apply -var "server_port=8080"
data.aws_availability_zones.all: Refreshing state...
.
.
.
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
.
.
.

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

elb_dns_name = terraform-hello-world-elb-257115914.us-west-1.elb.amazonaws.com
```

* Variables may also be set as environment variables (`TF_DEV_<VAR-NAME>`) or in a file using `-var-file` as shown below:

```bash
$ terraform apply -var-file dev_vars.tfvars
data.aws_availability_zones.all: Refreshing state...
aws_security_group.web_access: Refreshing state... [id=sg-0384d7b5c1306951c]
aws_security_group.elb_access: Refreshing state... [id=sg-0515982a6f679494c]
aws_launch_configuration.hello_world: Refreshing state... [id=terraform-20191009224535838400000001]
aws_elb.hello-world-elb: Refreshing state... [id=terraform-hello-world-elb]
aws_autoscaling_group.scale_hello: Refreshing state... [id=tf-asg-20191009224539125900000002]

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

elb_dns_name = terraform-hello-world-elb-257115914.us-west-1.elb.amazonaws.com
```

* Outputs defined in Terraform code are displayed once `terraform apply` completes or you can query:

```bash
$ terraform output
elb_dns_name = terraform-hello-world-elb-257115914.us-west-1.elb.amazonaws.com
```

* If all is good, you can have an application running quickly.

```bash
$ curl terraform-hello-world-elb-257115914.us-west-1.elb.amazonaws.com
Hello, World. Its Terraform time!
```

***

## Lessons Learned
* Terraform by design enforces immutable infrastructure. Changes to your code are tracked such that a minor update to a resource causes Terraform to tear down the required resource and rebuild it. This was a surprise to me as an Ansible user expecting idempotence.

Here is a change to user data in the autoscaling group:

```bash
$ terraform apply
var.server_port
  The port the server will use for HTTP requests

  Enter a value: 8080

data.aws_availability_zones.all: Refreshing state...
aws_security_group.web_access: Refreshing state... [id=sg-0ad080785a83c15ef]
aws_security_group.elb_access: Refreshing state... [id=sg-01ceefd2f2b461c88]
aws_launch_configuration.hello_world: Refreshing state... [id=terraform-20191009221901796000000001]
aws_elb.hello-world-elb: Refreshing state... [id=terraform-hello-world-elb]
aws_autoscaling_group.scale_hello: Refreshing state... [id=tf-asg-20191009221906381900000002]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  ~ update in-place
+/- create replacement and then destroy

Terraform will perform the following actions:

  # aws_autoscaling_group.scale_hello will be updated in-place
  ~ resource "aws_autoscaling_group" "scale_hello" {
        arn                       = "arn:aws:autoscaling:us-west-1:498234039551:autoScalingGroup:4bb89914-ca4f-461c-adfd-324752cfb834:autoScalingGroupName/tf-asg-20191009221906381900000002"
        availability_zones        = [
            "us-west-1b",
            "us-west-1c",
        ]
        default_cooldown          = 300
        desired_capacity          = 3
        enabled_metrics           = []
        force_delete              = false
        health_check_grace_period = 300
        health_check_type         = "ELB"
        id                        = "tf-asg-20191009221906381900000002"
      ~ launch_configuration      = "terraform-20191009221901796000000001" -> (known after apply)
        load_balancers            = [
            "terraform-hello-world-elb",
        ]
        max_size                  = 5
        metrics_granularity       = "1Minute"
        min_size                  = 3
        name                      = "tf-asg-20191009221906381900000002"
        protect_from_scale_in     = false
        service_linked_role_arn   = "arn:aws:iam::498234039551:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        suspended_processes       = []
        target_group_arns         = []
        termination_policies      = []
        vpc_zone_identifier       = []
        wait_for_capacity_timeout = "10m"

        tag {
            key                 = "Name"
            propagate_at_launch = true
            value               = "terraform-asg-hello-world"
        }
    }

  # aws_launch_configuration.hello_world must be replaced
+/- resource "aws_launch_configuration" "hello_world" {
        associate_public_ip_address      = false
      ~ ebs_optimized                    = false -> (known after apply)
        enable_monitoring                = true
      ~ id                               = "terraform-20191009221901796000000001" -> (known after apply)
        image_id                         = "ami-0dd655843c87b6930"
        instance_type                    = "t2.micro"
      + key_name                         = (known after apply)
      ~ name                             = "terraform-20191009221901796000000001" -> (known after apply)
        security_groups                  = [
            "sg-0ad080785a83c15ef",
        ]
      ~ user_data                        = "4430fd6498339061effa6d27ccf341a1e94569d7" -> "e102397f7b199cbf7b446fab2bfbd1bd9d7182ce" # forces replacement
      - vpc_classic_link_security_groups = [] -> null

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + no_device             = (known after apply)
          + snapshot_id           = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

Plan: 1 to add, 1 to change, 1 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_launch_configuration.hello_world: Creating...
aws_launch_configuration.hello_world: Creation complete after 1s [id=terraform-20191009223346108800000001]
aws_autoscaling_group.scale_hello: Modifying... [id=tf-asg-20191009221906381900000002]
aws_autoscaling_group.scale_hello: Modifications complete after 0s [id=tf-asg-20191009221906381900000002]
aws_launch_configuration.hello_world: Destroying... [id=terraform-20191009221901796000000001]
aws_launch_configuration.hello_world: Destruction complete after 0s

Apply complete! Resources: 1 added, 1 changed, 1 destroyed.

Outputs:

elb_dns_name = terraform-hello-world-elb-257115914.us-west-1.elb.amazonaws.com
```

* Removing the deployment is simple as well:

```bash
$ terraform destroy
var.server_port
  The port the server will use for HTTP requests

  Enter a value: 8080

data.aws_availability_zones.all: Refreshing state...
aws_security_group.web_access: Refreshing state... [id=sg-0ad080785a83c15ef]
aws_security_group.elb_access: Refreshing state... [id=sg-01ceefd2f2b461c88]
aws_launch_configuration.hello_world: Refreshing state... [id=terraform-20191009223346108800000001]
aws_elb.hello-world-elb: Refreshing state... [id=terraform-hello-world-elb]
aws_autoscaling_group.scale_hello: Refreshing state... [id=tf-asg-20191009221906381900000002]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:
.
.
.
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
.
.
.
```

* In order to verify changes, Terraform has to track state.
https://www.terraform.io/docs/state/index.html

When you run the example, Terraform creates a terraform.tfstate file locally. This is JSON data to track the state of the deployment.

## Additional References
* Getting started with Terraform: https://learn.hashicorp.com/terraform/getting-started/install.html
* Source code for the blog: https://github.com/gruntwork-io/intro-to-terraform
