#!/bin/bash
export AWS_REGION=$PT_aws_region
export FACTER_aws_region=$PT_aws_region
export FACTER_user=$PT_aws_user
puppet apply -e 'include awskit::create_bolt_workshop_master'