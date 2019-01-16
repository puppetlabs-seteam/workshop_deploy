
# Bolt Workshop automated deployment of PE with Bolt

To deploy PE in AWS with this module, do the following:

Add the following to your Puppetfile for Bolt:

```
# Modules from the Puppet Forge
mod 'puppetlabs-yumrepo_core', '1.0.2'

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
awskit::host_config:
  <your name>-awskit-boltws-master:
    public_ip: '<available elastic ip>'
```

for example:
```
awskit::host_config:
  kevin-awskit-boltws-master:
    public_ip: '35.180.221.85'
```


Then run the Bolt Plan like this:
```
bolt plan run workshop_deploy aws_region=[region] aws_user=[AWS user] github_user=[github user] github_pwd=[github password] --nodes [AWS public IP for PE master] --user centos --private-key [private key for SSH] --run-as root --no-host-key-check
```

for example:
```
bolt plan run workshop_deploy aws_region="eu-west-3" aws_user="user1" github_user="user1" github_pwd="password" --nodes 35.180.221.85 --user centos --private-key ./user1.key-eu-west-3.pem --run-as root --no-host-key-check
```

The parameters have the following meaning:
* aws_region: The AWS region (in Hiera) that awskit must use for deployment
* aws_user: The AWS user (in Hiera) that awskit must use for deployment
* github_user: Your GitHub user account that has access to github.com/puppetlabs-seteam
* github_pwd: Your GitHub user account password

You need the `--user centos --run-as root` options for Bolt since CentOS instances in AWS must be accessed via the `centos` user and then elevated to `root`.
