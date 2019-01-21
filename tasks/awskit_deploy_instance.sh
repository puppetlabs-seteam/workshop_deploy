#!/bin/bash
export AWS_REGION=$PT_aws_region
export FACTER_aws_region=$PT_aws_region
export FACTER_user=$PT_aws_user
puppet apply -e 'include awskit::create_bolt_workshop_master' --detailed-exitcodes --modulepath "${TASKDIR}/../..:$(puppet config print basemodulepath)"
retval=$?
if [ $retval -eq 0 ] || [ $retval -eq 2 ]; then
  exit 0
else
  exit $retval
fi
