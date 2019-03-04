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
                sh mvn clean install
                az logout
            """
        }
    }

    stage('Docker Image') {
        withDockerRegistry([credentialsId: dockerCredentialId, url: "http://${dockerRegistry}"]) {
            dir('target') {
                sh """
                    cp -f ../src/aks/Dockerfile .
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
              current_role="\$(kubectl --kubeconfig kubeconfig get services todoapp-service --output json | jq -r .spec.selector.role)"
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
        kubectl --kubeconfig=kubeconfig delete deployment "todoapp-deployment-\$TARGET_ROLE"
        """
    }

    stage('Deploy') {
        // Apply the deployments to AKS.
        // With enableConfigSubstitution set to true, the variables ${TARGET_ROLE}, ${IMAGE_TAG}, ${KUBERNETES_SECRET_NAME}
        // will be replaced with environment variable values
        acsDeploy azureCredentialsId: servicePrincipalId,
                  resourceGroupName: resourceGroup,
                  containerService: "${aks} | AKS",
                  configFilePaths: 'src/aks/deployment.yml',
                  enableConfigSubstitution: true,
                  secretName: dockerRegistry,
                  containerRegistryCredentials: [[credentialsId: dockerCredentialId, url: "http://${dockerRegistry}"]]
    }

    def verifyEnvironment = { service ->
        sh """
          endpoint_ip="\$(kubectl --kubeconfig=kubeconfig get services '${service}' --output json | jq -r '.status.loadBalancer.ingress[0].ip')"
          count=0
          while true; do
              count=\$(expr \$count + 1)
              if curl -m 10 "http://\$endpoint_ip"; then
                  break;
              fi
              if [ "\$count" -gt 30 ]; then
                  echo 'Timeout while waiting for the ${service} endpoint to be ready'
                  exit 1
              fi
              echo "${service} endpoint is not ready, wait 10 seconds..."
              sleep 10
          done
        """
    }

    stage('Verify Staged') {
        // verify the deployment through the corresponding test endpoint
        verifyEnvironment("todoapp-test-${newEnvironment()}")
    }

    stage('Switch') {
        // Update the production service endpoint to route to the new environment.
        // With enableConfigSubstitution set to true, the variables ${TARGET_ROLE}
        // will be replaced with environment variable values
        acsDeploy azureCredentialsId: servicePrincipalId,
                  resourceGroupName: resourceGroup,
                  containerService: "${aks} | AKS",
                  configFilePaths: 'src/aks/service.yml',
                  enableConfigSubstitution: true
    }

    stage('Verify Prod') {
        // verify the production environment is working properly
        verifyEnvironment('todoapp-service')
    }

    stage('Post-clean') {
        sh '''
          rm -f kubeconfig
        '''
    }
}

