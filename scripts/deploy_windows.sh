# requirements : 
# 1 - windows machine with flutter sdk and inno_setup installed
# 2 - bash shell for ex. git bash

# run : scripts/deploy_windows.sh

flutter build windows --release

cd dist

iscc build.iss

cd ../scripts

./sign_windows.sh

if [ $? -ne 0 ]; then
  echo "Error signing the exe file"
  exit 1
fi

./upload_windows.sh