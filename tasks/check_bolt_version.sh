version=$(bolt --version)
major=`echo $version | cut -d. -f1`
minor=`echo $version | cut -d. -f2`
revision=`echo $version | cut -d. -f3`

if [ $major -ge 1 ] && [ $minor -ge 16 ]; then
    exit 0
else
    exit 1
fi