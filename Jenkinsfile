pipeline {
    agent any
    environment {
        AWS_CRED = credentials('dfc9e103-3678-426e-89b5-e670590c1b30')
        AWS_DEFAULT_REGION = 'us-east-1'
        
    }
    stages {
        stage ('Clone') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']], 
                    extensions: [], 
                    userRemoteConfigs: [[credentialsId: 'eb0e167d-13d9-4045-8240-760541fd6d79', 
                                         url: 'https://github.com/gunal-123/TerraformPOC.git']])
            }
        }
        stage ('backend_bucket') {
            steps {
                dir('backend_bucket') {
                   sh(script: '''terraform init
                                 terraform validate
                                 terraform fmt
                                 terraform plan -out=tfplan
                                 terraform apply -auto-approve tfplan'''
                      )
                
                    script {
                        env.BACKEND_BUCKET = sh(
                            script: 'terraform output -raw backend_bucket_name',
                            returnStdout: true
                            ).trim()
                            
                    }
                    
                }
            }
        }
        stage ('initialization') {
            steps {
                sh 'echo env.BACKEND_BUCKET'
                sh 'pwd'
                sh '''terraform init -reconfigure \
                         -backend-config="bucket=${BACKEND_BUCKET}"
                      terraform validate'''
            }
            }
        
        stage ('plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }
        stage ('approve') {
            steps {
                timeout(activity: true, time: 1) {
                     input cancel: 'abort.... abort.... abort', 
                    id: '1', 
                    message: 'Do you want to perform these actions? Proceed or Abort', 
                    ok: 'Approve', 
                    submitter: 'cloud_user', submitterParameter: 'Approver'              }
                
            }
        }
        stage ('apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            
            script {
                env.primary_bucket = sh(
                    script: 'terraform output -raw primary_bucket_name',
                    returnStdout: true
                    ).trim()
                
                env.secondary_bucket = sh(
                    script: 'terraform output -raw secondary_bucket_name',
                    returnStdout: true
                    ).trim()
            }
        }
        }
        
        
    }
}
