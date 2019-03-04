node('master') {

    //def servicePrincipalId = '04d30485-dd26-42f0-bc3f-9c94be7f0c9a'
    
    stage('SCM') {
        checkout scm
    }

    stage('Build') {
          ([azureServicePrincipal('04d30485-dd26-42f0-bc3f-9c94be7f0c9a')]) {
            sh """
                az login --service-principal -u "\$AZURE_CLIENT_ID" -p "\$AZURE_CLIENT_SECRET" -t "\$AZURE_TENANT_ID"
                az account set --subscription "\$AZURE_SUBSCRIPTION_ID"
                az logout
            """
        }
    }

}

