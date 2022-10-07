#!/usr/bin/env groovy
def askUserInput(String message,String multipleChoise,String defaultChoice,int time) {
    def userInput = defaultChoice
    try{
        timeout(time: time, unit: 'SECONDS') {
        userInput = input message: message, ok: 'OK', parameters: [choice(name: 'USERINPUT', choices: multipleChoise, defaultChoice: defaultChoice, description: message)] }
    } catch (err) {
        defaultChoice
    }
    echo "User select : ${userInput}"
    userInput
}

def getEnvName(branchName) {
    if("origin/develop".equals(branchName)) {
        return "DEV";
    } else if ("origin/master".equals(branchName)) {
        return "PROD";
    } else if ("origin/release".equals(branchName)) {
        return "PREPROD";
    }
}

pipeline {
    agent any
    environment {
        TERRAFORM_PLAN_FILE="DEMO"
        ENV_NAME = getEnvName(env.GIT_BRANCH)
    }

    tools {
        terraform 'terraform_1.3.2'
    }

    stages {
        stage ("Setup Deployment Environment") {
            steps {
                script {

                    echo "branch name: ${env.GIT_BRANCH}"
                    echo "env name: ${env.ENV_NAME.toLowerCase()}"
                    load "envvars/${env.ENV_NAME.toLowerCase()}.groovy"
                }
            }
        }
        stage ("Pre-build operations") {
            steps {
                cleanWs notFailBuild: false
                checkout scm
            }
        }
        stage('TF Init and validations checks') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws-credentials",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                ]]) {
                    echo "${env.ENV_NAME.toLowerCase()}"
                    echo 'Validating terraform scripts . . .'
                    sh "terraform version"
                    sh "terraform init -no-color"
                    sh "terraform workspace select ${env.ENV_NAME} -no-color"
                    sh "terraform validate -no-color"
                }
            }
        }
        stage('TF Destroy Plan creation') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws-credentials	",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                ]]) {
                    echo "${env.ENV_NAME.toLowerCase()}"
                    echo 'Validating terraform scripts . . .'
                    sh "terraform version"
                    sh "terraform init -no-color"
                    sh "terraform workspace select ${env.ENV_NAME} -no-color"
                    sh "terraform plan -destroy -no-color -input=false -out ${TERRAFORM_PLAN_FILE}-${ENV_NAME}.plan"
                }
            }
        }
        stage('TF Destroy') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws-credentials	",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY',
                ]]) {
                    script {
                        approve_plan=askUserInput("Destroy Terraform plan?","NO\nYES","NO",300)
                        if( approve_plan == "YES"){
                            echo "${env.ENV_NAME.toLowerCase()}"
                            echo 'Validating terraform scripts . . .'
                            sh "terraform version"
                            sh "terraform init -no-color"
                            sh "terraform workspace select ${env.ENV_NAME} -no-color"
                            sh "terraform apply -destroy -no-color -input=false ${TERRAFORM_PLAN_FILE}-${ENV_NAME}.plan"
                        } else{
                            echo "TF plan not approved. Skip Apply . . . "
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs(cleanWhenNotBuilt: false,
            deleteDirs: true,
            disableDeferredWipeout: true,
            notFailBuild: true,
            patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
            [pattern: '.propsfile', type: 'EXCLUDE']])
        }
    }
}