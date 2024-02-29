# Boundary Docker Compose Project


## Reset admin password
```
export BOUNDARY_ADDR=localhost

ADMIN_ACCOUNT_ID=$(boundary users list -keyring-type=none -recovery-config ./conf/boundary.hcl -format json | jq -rc '.items[] | select(.name == "admin")' | jq -rc '.primary_account_id')

boundary accounts set-password -id $ADMIN_ACCOUNT_ID -keyring-type=none -recovery-config ./conf/boundary.hcl
```

## Boundary user login via oidc
```
export BOUNDARY_ADDR=localhost

if [ ! -f ~/.gnupg/pubring.kbx ]; then
  gpg2 --batch --passphrase '' --quick-gen-key mykey default default
  pass init mykey
fi

#AUTH_METHOD_ID=$(boundary auth-methods list -format json -keyring-type none | jq -rc '.items[] | select(.type == "oidc" and .scope_id =="global")' | jq -rc '.id')
#boundary authenticate oidc -auth-method-id $AUTH_METHOD_ID

boundary authenticate oidc
```

## SSH Key rotation script

The following script will go over all targets defined in Boundary and rotate SSH keys:
```
export BOUNDARY_ADDR=localhost
export GLOBAL_SCOPE=`boundary scopes list -format=json | jq -r '.items[] | .id'`
TODAY=$(date +'%Y-%m-%d')
echo "dumping targets"
readarray -t TARGETS < <(boundary targets list -scope-id=$GLOBAL_SCOPE -recursive -format=json | jq -rc '.items[] | [.id, .name]')
for TARGET in "${TARGETS[@]}"; do
  echo "----------------------------------------------------------------"
  TARGET_HOST=$(echo $TARGET | jq -rc '.[1]' | tr '[:upper:]' '[:lower:]')
  TARGET_ID=$(echo $TARGET | jq -rc '.[0]')
  echo "target $TARGET, host $TARGET_HOST, id $TARGET_ID"
  readarray -t HOST_KEYS < <(boundary targets read -id $TARGET_ID -format json | jq -rc '.item.injected_application_credential_sources[].id')
  for HOST_KEY in "${HOST_KEYS[@]}"; do
    echo "host key $HOST_KEY"
    #sanity check
    CRED_USER=$(boundary credentials read -id $HOST_KEY -format json | jq '.item | select(.type == "ssh_private_key")' | jq -rc '.attributes.username')
    echo $CRED_USER
    if [ -n "$CRED_USER" ]; then
      KEY_NAME="$TARGET_HOST-$CRED_USER-$TODAY"
      echo "Dumping old ~/.ssh/authorized_keys" 
      echo "cat ~/.ssh/authorized_keys" | boundary connect ssh -target-id $TARGET_ID
      if [ $? -eq 0 ]; then
        echo "generate new key pair"
        rm -rf /tmp/k1* ; ssh-keygen -t rsa -b 4096 -C $KEY_NAME -N "" -f /tmp/k1
        PUBLIC_FILE=$(<"/tmp/k1.pub")
        if [ $? -eq 0 ]; then
          echo "update credentials"
          echo "echo $PUBLIC_FILE >> ~/.ssh/authorized_keys" | boundary connect ssh -target-id $TARGET_ID
          boundary credentials update ssh-private-key -id $HOST_KEY -name $KEY_NAME -username $CRED_USER -private-key file:///tmp/k1
          echo TEST: boundary connect ssh -target-id $TARGET_ID
        fi
      fi
    fi
  done
done
rm -rf /tmp/k1*
```
