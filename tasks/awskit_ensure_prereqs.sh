#!/bin/bash
echo "Info: Checking if all prereqs for AWSKit have been met..."

echo "Info: Checking if XCode Commandline Developer Tools are installed..."
xcode-select -p
if [ $? -eq 0 ]; then
  echo "Info: XCode Commandline Developer Tools are installed, continuing..."
else
  echo "Error: XCode Tools are NOT installed! Run 'xcode-select --install' first."
  exit 1
fi

echo "Info: Checking if AWSCLI is installed..."
aws --version
if [ $? -eq 0 ]; then
  echo "Info: AWSCLI is installed, continuing..."
else
  echo "Error: AWSCLI is NOT installed! Run 'brew install awscli' first."
  exit 1
fi

echo "Info: Checking if AWSCLI has been configured..."
if [ ! -f ~/.aws/config ] || [ ! -f ~/.aws/credentials ]; then
  echo "Error: AWSCLI is NOT configured! Run 'awscli configure' first."
  exit 1
else
  echo "Info: AWSCLI is configured, continuing..."
fi

echo "Info: Checking if the AWS-SDK gem is installed..."
/opt/puppetlabs/puppet/bin/gem list | grep aws-sdk
if [ $? -eq 0 ]; then
  echo "Info: AWS-SDK gem is installed, continuing..."
else
  echo "Error: AWS-SDK gem is NOT installed! Run 'sudo /opt/puppetlabs/puppet/bin/gem install aws-sdk retries --no-ri --no-rdoc' first."
  exit 1
fi

echo "Info: Checking if the Retries gem is installed..."
/opt/puppetlabs/puppet/bin/gem list | grep retries
if [ $? -eq 0 ]; then
  echo "Info: Retries gem is installed, continuing..."
else
  echo "Error: Retries gem is NOT installed! Run 'sudo /opt/puppetlabs/puppet/bin/gem install aws-sdk retries --no-ri --no-rdoc' first."
  exit 1
fi

echo "Info: Checking if the puppetlabs-stdlib module is installed..."
puppet module list | grep "puppetlabs-stdlib"
if [ $? -eq 0 ]; then
  echo "Info: puppetlabs-stdlib module is installed, continuing..."
else
  echo "Error: puppetlabs-stdlib module is NOT installed! Run 'puppet module install puppetlabs/stdlib' first."
  exit 1
fi

echo "Info: Checking if the puppetlabs-aws module is installed..."
puppet module list | grep "puppetlabs-aws"
if [ $? -eq 0 ]; then
  echo "Info: puppetlabs-aws module is installed, continuing..."
else
  echo "Error: puppetlabs-aws module is NOT installed! Run 'puppet module install puppetlabs/aws' first."
  exit 1
fi

echo "Info: Checking if the timidri-awskit module is installed..."
puppet module list | grep "timidri-awskit"
if [ $? -eq 0 ]; then
  echo "Info: timidri-awskit module is installed, making sure it is up-to-date..."
else
  echo "Info: timidri-awskit module is not installed, installing module now..."
  cd ~/.puppetlabs/etc/code/modules
  git clone https://github.com/puppetlabs-seteam/awskit.git
  echo "Info: timidri-awskit module is now installed, continuing..."
fi
echo "All prereqs checked and passed!"