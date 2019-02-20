
# Bolt Workshop automated deployment of PE with Bolt

**Note: the deployment of AWS instances through this Bolt Plan currently does not work if you're using the bastion account**
**This is due to the temporary MFA credentials (in your environment vars) not getting to the plan's runtime context**
**A solution for this problem is being investigated**

To deploy PE in AWS with this module, do the following:

Add the following to your Puppetfile for Bolt:

```
# Modules from the Puppet Forge
mod 'puppetlabs-stdlib',       '5.2.0'
mod 'puppetlabs-aws',          '2.1.0'
mod 'puppetlabs-yumrepo_core', '1.0.3'

# Modules from Git
mod 'workshop_deploy',
  :git => 'https://github.com/puppetlabs-seteam/workshop_deploy.git',
  :ref => 'master'

mod 'awskit',
  :git => 'https://github.com/puppetlabs-seteam/awskit.git',
  :ref => 'master'
```

and run `bolt puppetfile install` to sync the modules.

Make sure you have previously configured awskit to deploy a CentOS image for the Bolt workshop that uses a fixed Elastic IP. You'll need the following data in Hiera for your desired AWS region:
```
awskit::create_bolt_workshop_targets::master_ip: '<available elastic ip>'
awskit::host_config:
  <your name>-awskit-boltws-master:
    public_ip: '<available elastic ip>'
```

for example:
```
awskit::create_bolt_workshop_targets::master_ip: '35.180.221.85'
awskit::host_config:
  kevin-awskit-boltws-master:
    public_ip: '35.180.221.85'
```


Then run the Bolt Plan like this:
```
bolt plan run workshop_deploy awsregion=[region] awsuser=[AWS user] github_user=[github user] github_pwd=[github password] --nodes [AWS public IP for PE master] --user centos --private-key [private key for SSH] --run-as root --no-host-key-check
```

for example:
```
bolt plan run workshop_deploy awsregion="eu-west-3" awsuser="user1" github_user="user1" github_pwd="password" --nodes 35.180.221.85 --user centos --private-key ./user1.key-eu-west-3.pem --run-as root --no-host-key-check
```

The parameters have the following meaning:
* aws_region: The AWS region (in Hiera) that awskit must use for deployment
* aws_user: The AWS user (in Hiera) that awskit must use for deployment
* github_user: Your GitHub user account that has access to github.com/puppetlabs-seteam
* github_pwd: Your GitHub user account password

You need the `--user centos --run-as root` options for Bolt since CentOS instances in AWS must be accessed via the `centos` user and then elevated to `root`.


## Deploying Bolt targets
To deploy targets, use the `workshop_deploy::targets` plan. This plan will:
* Deploy 1 Linux and 1 Windows target for the Bolt instructor
* Deploy 1 Linux and 1 Windows target for the amount of students specified

```
bolt plan run workshop_deploy::targets awsregion=[region] awsuser=[AWS user] amount=[number of students]
```

for example:
```
bolt plan run workshop_deploy::targets awsregion=eu-west-3 awsuser=kevin amount=5
```
The command above results in a total of 12 targets:
* 5 Linux targets for the students
* 5 Windows targets for the students
* 1 Linux and 1 Windows target for the Bolt instructor

Make sure the AWS region you select has a high enough limit for simultaneous running instances!
Check here for your current limits: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html

The plan uses AWSkit to create the instances, and AWSkit has been configured to expect a 'bolt_ws_key' as the key for any region that you specify. This key may not have been setup yet for your region. To verify, look for a 'bolt_ws_key' entry in the 'Key Pairs' section in your AWS console.

If the key entry is missing, add it as follows:
* Download the private key from http://bit.ly/B0ltk3y
* Generate the public key from the private key by running `ssh-keygen -y -f bolt_ws_key.pem`
* Under 'Key Pairs' in the AWS console, click 'Import Key Pair', set the name to `bolt_ws_key` and paste the public key value
