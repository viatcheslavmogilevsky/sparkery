Sparkery - infrastructure template for Spark cluster on AWS
=====

### Prerequisites

1. virtualenv with needed python packages, I prefer to have separate environment locally (content under .gitignore):
``` bash
$ virtualenv .virtualenv
$ . .virtualenv/bin/activate
$ pip install -r requirements.txt
```

2.  [Packer](https://www.packer.io/), I prefer to place packer binary into .virtualenv/bin
3.  [Terraform](https://www.terraform.io/),  I prefer to place terraform binary into .virtualenv/bin
4.  AWS account and its credentials - I prefer to have `env` file which loads credentails into environment variables:
``` bash
$ . secrets/env
```
    See secrets/env.example - this is only one file in secrets directory which tracked by git - see .gitignore.

### Bootstrap

1.  Generate and download keypair for EC2 instances:
``` bash
$ ansible-playbook keypair.yml
```

2.  Build your private AMI by packer:
``` bash
$ packer build common-ami.json
```

3. Build infrastructure by terraform:
``` bash
$ terraform apply
```
    then go to aws console - you should see running instances

### Usage

Start/stop EC2 instances:
``` bash
$ ./start-ec2.py # instances are already running after `terraform apply`, you can skip this
$ ./stop-ec2.py
```

Start/stop spark standalone:
``` bash
$ ansible-playbook site.yml
$ ansible tag_Name_sparkery_master  -m shell -a "/usr/lib/spark/sbin/start-all.sh"
$ ansible tag_Name_sparkery_master  -m shell -a "/usr/lib/spark/sbin/stop-all.sh"
```
