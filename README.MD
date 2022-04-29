# Scaling APIM + Functions + CosmosDB

An Azure Bicep implementation of: https://francescodeliva.medium.com/can-cloud-native-go-20-000-transactions-per-second-42ce8022e4

## Highlights

* APIM (Dev SKU) deployed into Vnet with external IP
* Premium Functions
  * Vnet integration
  * Private endpoint ingress
  * Private storage/content
* CosmosDB (SQL API) with Private Endpoints
* [Github Actions authentication with Azure using OpenID Connect](./.github/workflows/README.MD)