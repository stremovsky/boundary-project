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
