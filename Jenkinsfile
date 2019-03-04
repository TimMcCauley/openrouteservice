node('master') {

    def servicePrincipalId = '04d30485-dd26-42f0-bc3f-9c94be7f0c9a'
    def resourceGroup = 'orsResourceGroup'
    def aks = 'orsKubernetesAKS'

    def dockerRegistry = 'orscontainerregistry.azurecr.io'
    def imageName = 'todo-app:${env.BUILD_NUMBER}'
    env.IMAGE_TAG = '${dockerRegistry}/${imageName}'
    def dockerCredentialId = '/subscriptions/cbd91219-7204-4531-81d0-b1f4bee7fe05/resourceGroups/orsResourceGroup/providers/Microsoft.ContainerRegistry/registries/orsContainerRegistry'

    def currentEnvironment = 'blue'
    def newEnvironment = { ->
        currentEnvironment == 'blue' ? 'green' : 'blue'
    }

    stage('SCM') {
        checkout scm
    }

    stage('Build') {
          ([azureServicePrincipal(servicePrincipalId)]) {
            sh """
                az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
                az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
                az logout
            """
        }
    }

}

