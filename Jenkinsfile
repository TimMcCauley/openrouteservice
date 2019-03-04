node('master') {

    def servicePrincipalId = 'c1d750ff-1e0d-4eb3-9bf2-aedc25a12be1'
    def resourceGroup = 'orsResourceGroup'
    def aks = 'orsKubernetesAKS'

    def dockerRegistry = 'orscontainerregistry.azurecr.io'
    def imageName = "todo-app:${env.BUILD_NUMBER}"
    env.IMAGE_TAG = "${dockerRegistry}/${imageName}"
    def dockerCredentialId = '/subscriptions/cbd91219-7204-4531-81d0-b1f4bee7fe05/resourceGroups/orsResourceGroup/providers/Microsoft.ContainerRegistry/registries/orsContainerRegistry'

    def currentEnvironment = 'blue'
    def newEnvironment = { ->
        currentEnvironment == 'blue' ? 'green' : 'blue'
    }

    stage('SCM') {
        checkout scm
    }

    stage('Build') {
        withCredentials([azureServicePrincipal(servicePrincipalId)]) {
            sh """
                az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
                az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
                //sh mvn clean install
                az logout
            """
        }
    }

    stage('Docker Image') {
        withDockerRegistry([credentialsId: dockerCredentialId, url: "http://${dockerRegistry}"]) {
            dir('target') {
                sh """
                    //cp -f ../src/aks/Dockerfile .
                    docker build -t "${env.IMAGE_TAG}" .
                    docker push "${env.IMAGE_TAG}"
                """
            }
        }
    }

}

