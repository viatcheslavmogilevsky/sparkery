#!/usr/bin/env python

from boto import ec2
import os

if __name__ == "__main__":
    conn = ec2.connect_to_region(os.environ.get("AWS_REGION"),
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"))
    instances = conn.get_only_instances(
        filters={"tag:Environment" : "sparkery"})
    ids = map(lambda i: i.id, instances)
    print conn.start_instances(ids)
