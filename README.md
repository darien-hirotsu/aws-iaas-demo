# Infrastructure as Code Demo using Terraform and AWS

## Overview
This demo is based on the awesome resource below which walks through a simple Terraform "Hello world!" example.
https://blog.gruntwork.io/an-introduction-to-terraform-f17df9c6d180

In the example above, you will create a simple web server running in AWS using Terraform. Then you expand by creating an autoscaling group with an ELB front end. The example contained in this repository deploys the autoscaling group with some with some minor tweaks. I updated some details compared to the original like Terraform resource names, AWS region names, etc. to help absorb concepts.

## Installation and Setup
* The blog shown in the `Overview` section walks through all of the required installation including how to install the Terraform binary and how to setup a simple IAM account using the AWS free tier.

* I'm using Atom as my IDE with the `language-terraform` package to help with syntax highlighting and the typical bells and whistles. Definitely worth it!
https://atom.io/packages/language-terraform

* I'm using this .gitignore file to keep any Terraform artifacts out of the repository.
https://github.com/github/gitignore/blob/master/Terraform.gitignore

## Running
* Once you complete `Installation and Setup` always remember to first set the AWS authentication environment variables in any new shell you use to run the code.
```bash
export AWS_SECRET_ACCESS_KEY=<YOUR-KEY>
export AWS_ACCESS_KEY_ID=<YOUR-KEY-ID>
```

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

elb_dns_name = terraform-hello-world-elb-185301025.us-west-1.elb.amazonaws.com
```

* Outputs defined in Terraform code are displayed once `terraform apply` completes or you can query:

```bash
$ terraform output
elb_dns_name = terraform-hello-world-elb-185301025.us-west-1.elb.amazonaws.com
```

***

## Lessons Learned
1. Terraform by design enforces the concept of immutable infrastructure. Changes to your code are tracked such that even a minor update to a resource causes Terraform to tear down the environment before rebuilding. This was a surprise to me as an Ansible user expecting idempotence.

## Additional References
* Getting Started with Terraform: https://learn.hashicorp.com/terraform/getting-started/install.html
