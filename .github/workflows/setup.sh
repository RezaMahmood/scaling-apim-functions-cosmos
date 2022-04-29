#!/bin/bash
echo "Log in your Azure subscription"
#az login
az login --scope 'https://graph.microsoft.com//.default'

echo " "
echo " "
echo " "
echo " "
echo " "

echo "Setting up Azure Service Principal"
echo "Please provide the subscription Id for the Azure environment you wish to connect:"

read subscriptionId

echo " "
echo "Please provide the resource group you wish to scope to - leave blank to scope to entire subscription:"
read resourceGroup

echo " "
echo "Please provide the role you wish Github deployment to use (defaults to Contributor if blank):"
read role

echo " "
echo "Creating Service Principal with role..."

if [ -z "$role" ]
then
    role="contributor"
fi

if [ -z "$resourceGroup" ]
then
    rbacObject=$(az ad sp create-for-rbac --scopes /subscriptions/$subscriptionId --role $role)
else
    rbacObject=$(az ad sp create-for-rbac --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroup --role $role)
fi

appId=$(echo $rbacObject | jq -rc '.appId')
tenant=$(echo $rbacObject | jq -rc '.tenant')

appObject=$(az ad app show --id $appId)
appObjectId=$(echo $appObject | jq -rc '.objectId')

echo " "
echo "Federated Credentials"
echo "Enter the name of this Federated Credential (spaces are not allowed)"
read federatedcredentialname

echo " "
echo "Enter the repo scope (e.g. <orgname>/<reponame>:ref:refs/heads/<repobranch>"
read federatedcredentialsubject

echo " "
echo "Enter a description"
read federatedcredentialdescription



uri=$(echo "https://graph.microsoft.com/beta/applications/${appObjectId}/federatedIdentityCredentials")
body=$(echo "{\"name\":\""${federatedcredentialname}"\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\""${federatedcredentialsubject}"\",\"description\":\""${federatedcredentialdescription}"\",\"audiences\":[\"api://AzureADTokenExchange\"]}")

echo " "
echo "Setting up Federated Credentials"

az rest --method POST --headers 'Content-Type=application/json' --uri $uri --body "$body"

echo " "
echo " "
echo "Verifying credential.  You should see a federated credential for the SP you just created"
federatedcredentials=$(az rest -m GET -u "https://graph.microsoft.com/beta/applications/$appObjectId/federatedIdentityCredentials")

echo $federatedcredentials

echo " "
echo " "
echo " "
echo "If you do not see expected credentials (above) you should delete this SP and retry the process.  Use 'az ad sp delete --id $appId'"
echo " "
echo " "
echo " "
echo "Next step: Create secrets in your github repo as follows"


echo "GithubSecretKey Value
AZURE_CLIENT_ID ${appId}
AZURE_TENANT_ID ${tenant}
AZURE_SUBSCRIPTION_ID ${subscriptionId}" | column -t