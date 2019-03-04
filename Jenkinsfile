node('master') {

    def servicePrincipalId = '04d30485-dd26-42f0-bc3f-9c94be7f0c9a'
    def resourceGroup = 'orsResourceGroup'
    def aks = 'orsKubernetesAKS'

    def dockerRegistry = 'orscontainerregistry.azurecr.io'
    def imageName = "ors-app:${env.BUILD_NUMBER}"
    env.IMAGE_TAG = "${dockerRegistry}/${imageName}"
    def dockerCredentialId = '88199ed2-a084-4bf2-8091-8bee8070142a'

    def currentEnvironment = 'blue'
    def newEnvironment = { ->
        currentEnvironment == 'blue' ? 'green' : 'blue'
    }

    stage('SCM') {
        checkout scm
        sh "git checkout development"
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
            dir('.') {
                sh """
                    docker build -t "${env.IMAGE_TAG}" .
                    docker push "${env.IMAGE_TAG}"
                """
            }
        }
    }

    stage('Check Env') {
        // check the current active environment to determine the inactive one that will be deployed to

        withCredentials([azureServicePrincipal(servicePrincipalId)]) {
            // fetch the current service configuration
            sh """
              az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
              az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
              az aks get-credentials --resource-group "${resourceGroup}" --name "${aks}" --admin --file kubeconfig
              az logout
              current_role="\$(kubectl --kubeconfig kubeconfig get services ors-service --output json | jq -r .spec.selector.role)"
              if [ "\$current_role" = null ]; then
                  echo "Unable to determine current environment"
                  exit 1
              fi
              echo "\$current_role" >current-environment
            """
        }

        // parse the current active backend
        currentEnvironment = readFile('current-environment').trim()

        // set the build name
        echo "***************************  CURRENT: $currentEnvironment     NEW: ${newEnvironment()}  *****************************"
        currentBuild.displayName = newEnvironment().toUpperCase() + ' ' + imageName

        env.TARGET_ROLE = newEnvironment()

        // clean the inactive environment
        sh """
          kubectl --kubeconfig=kubeconfig delete deployment "orsapp-deployment-\$TARGET_ROLE"
        """
    }


}

