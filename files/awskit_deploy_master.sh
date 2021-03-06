#!/bin/bash
for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            bastion)     bastion=${VALUE} ;;
            awsregion)   awsregion=${VALUE} ;;
            awsuser)     awsuser=${VALUE} ;;
            awskeyid)    awskeyid=${VALUE} ;;
            awssecret)   awssecret=${VALUE} ;;
            awssession)  awssession=${VALUE} ;;
            *)   
    esac    
done

export AWS_REGION=$awsregion
export FACTER_aws_region=$awsregion
export FACTER_user=$awsuser

echo "AWS Region is: $AWS_REGION"
echo "Facter AWS Region is: $FACTER_aws_region"
echo "Facter AWS User is: $FACTER_user"

if [ "$bastion" = true ]; then
  export AWS_ACCESS_KEY_ID=$awskeyid
  export AWS_SECRET_ACCESS_KEY=$awssecret
  export AWS_SESSION_TOKEN=$awssession
  echo "AWS Access Key is: $AWS_ACCESS_KEY_ID"
  echo "AWS Secret Key is: $AWS_SECRET_ACCESS_KEY"
  echo "AWS Session Token: $AWS_SESSION_TOKEN"
fi

puppet apply -e "include awskit::create_bolt_workshop_master" --detailed-exitcodes
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