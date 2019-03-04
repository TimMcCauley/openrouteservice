node('master') {

    def servicePrincipalId = '04d30485-dd26-42f0-bc3f-9c94be7f0c9a'
    def resourceGroup = 'orsResourceGroup'
    def aks = 'orsKubernetesAKS'

    def dockerRegistry = 'orscontainerregistry.azurecr.io'
    def imageName = "todo-app:${env.BUILD_NUMBER}"
    env.IMAGE_TAG = "${dockerRegistry}/${imageName}"
    def dockerCredentialId = '88199ed2-a084-4bf2-8091-8bee8070142a'

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
                az logout
            """
        }
    }

    stage('Docker Image') {
        withDockerRegistry([credentialsId: dockerCredentialId, url: "http://${dockerRegistry}"]) {
            dir('target') {
                sh """
                    docker build -t "${env.IMAGE_TAG}" .
                    docker push "${env.IMAGE_TAG}"
                """
            }
        }
    }

}

