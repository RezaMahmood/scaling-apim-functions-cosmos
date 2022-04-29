# Setting up Github to deploy to Azure

## Objectives:

1. **Configure Github to use Azure credentials**
    <br>[Generate deployment credentials](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-github-actions?tabs=CLI#generate-deployment-credentials)<br>
    [Add Federated Credentials](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#add-federated-credentials)<br>
    [Create Github Secrets](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#create-github-secrets
    )<br>
    [Test and Verify OpenID Connect Connection](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#set-up-azure-login-with-openid-connect-authentication)<br>
    [Create Github Secrets](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#create-github-secrets)<br>
2. **Use Self hosted runners to deploy into locked down virtual network**
   <br>(https://colinsalmcorner.com/on-demand-ephemeral-self-hosted-runners/)


   ## Configure Github to use Azure credentials
   In order to deploy to Azure from a Github Action we will need to create a Service Principal that represents a Github Action and has the appropriate permissions to perform deployments.<br><br>

   We want to be able to use Azure credentials without having to maintain secrets or passwords.  This can be achieved using OpenID Connect and Federated Credentials.  This effectively allows a Github repo to authenticate with Azure to retrieve a token with permissions without needing to store passwords in Github.<br><br>

   Run the script ([setup.sh](./setup.sh)) and follow the prompts to set up federated credentials which you will then need to store as Repository secrets.<br><br>

   You will need:
   - Azure credentials to log in
   - Subscription ID
   - [Optional] Scope that you wish Github to have access on Azure - for example resource group name (leave blank to grant across entire subscription)
   - [Optional] The role you want to grant the Service Principal (defaults to Contributor)
   - Name for the Federated Credential
     - Cannot contain spaces - something to refer back to later
   - The Repo and Scope that the identity will have access to.  For example, for this repo it would be "rezamahmood/scaling-apim-functions-cosmos:ref:refs/heads/main".  This indicates that the credential will only authenticate if a Github Action is executed from the main branch of this specific repo.  You could put someone else's repo in here by "accident" and still create a federated identity, however, you would get an error because you wouldn't be able to access that other person's repo.
   - A friendly description for the federated credential

<br><br>
On successful completion of the script you will be presented with the TenantID, ClientID and SubscriptionID that you can add to your Github Repo as Secrets. No passwords or Service Principal secrets required anymore.<br><br>
If for some reason the script fails or you wish to delete the SP because you're just testing then the script will provide the right command to delete the Service Principal you have created.  The associated Federated Credential will be deleted as well.

### Future Enhancements
Integration with Github APIs to automate repo secrets creation ([the last step](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#create-github-secrets)).  A use case is for the fully automated set up and integration for Dev teams using Github and Azure.
