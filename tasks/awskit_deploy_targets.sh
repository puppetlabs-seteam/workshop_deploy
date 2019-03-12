#!/bin/bash
export AWS_REGION=$PT_awsregion
export FACTER_aws_region=$PT_awsregion
export FACTER_user=$PT_awsuser

echo "AWS Region is: $AWS_REGION"
echo "Facter AWS Region is: $FACTER_aws_region"
echo "Facter AWS User is: $FACTER_user"

if [ "$PT_bastion" = true ]; then
  export AWS_ACCESS_KEY_ID=$PT_awskeyid
  export AWS_SECRET_ACCESS_KEY=$PT_awssecret
  export AWS_SESSION_TOKEN=$PT_awssession
fi

puppet apply -e "class {'awskit::create_bolt_workshop_targets': count => $PT_amount }" --detailed-exitcodes
result=$?

if [ $result -eq 0 ]; then
  echo "No changes needed."
elif [ $result -eq 2 ]; then
  echo "Changes successfully applied."
  exit 0
else
  echo "Problems applying changes!"
  exit $result
fi