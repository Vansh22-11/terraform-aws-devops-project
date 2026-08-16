pipeline {

    agent {
        label 'dynamic-agent'
    }

    parameters {

    choice(
        name: 'DEPLOYMENT_MODE',
        choices: [
            'Create / Update Infrastructure',
            'Destroy and Rebuild'
        ],
        description: 'Choose Terraform Deployment Mode'
    )

}

    environment {

        AWS_DEFAULT_REGION = 'eu-north-1'
        TF_IN_AUTOMATION   = 'true'
        ANSIBLE_DIR = "ansible"
    
        STATE_EXISTS       = 'false'
        INSTANCE_ID        = ''
        INSTANCE_STATE     = ''

    
    
    }   


    options {

        timestamps()
        ansiColor('xterm')

    }

    stages {

        stage('Checkout Source') {

            steps {

                echo "========== CHECKOUT SOURCE =========="
                checkout scm

            }

        }

        stage('Verify Tools') {

            steps {

                sh '''
                echo "========== VERIFY TOOL VERSIONS =========="

                echo ""
                echo "Terraform Version:"
                terraform version

                echo ""
                echo "AWS CLI Version:"
                aws --version

                echo ""
                echo "Git Version:"
                git --version

                echo ""
                echo "Java Version:"
                java -version

                echo ""
                echo "Current Directory:"
                pwd

                echo ""
                echo "Project Files:"
                ls -la
                '''

            }

        }

        stage('Terraform Init') {

            steps {

                echo "========== TERRAFORM INIT =========="

                sh '''
                terraform init -reconfigure
                '''

            }

        }

        stage('Detect Terraform State') {

            steps {

                script {

                    def stateResources = sh(
                    script: '''
                    terraform state list 2>/dev/null || true
                    ''',
                    returnStdout: true
                    ).trim()

                    if (stateResources) {

                    env.STATE_EXISTS = 'true'

                    echo """
                    ==================================================
                    TERRAFORM STATE DETECTION
                    ==================================================
                    State found.
                    Terraform is already managing infrastructure.

                    Resources:
                    ${stateResources}
                    ==================================================
                    """

                    } else {

                    env.STATE_EXISTS = 'false'

                    echo """
                    ==================================================
                    TERRAFORM STATE DETECTION
                    ==================================================
                    No Terraform resources found in state.

                    This is a FIRST DEPLOYMENT.

                    Terraform will create the infrastructure.
                    ==================================================
                """
                }
                }
            }
        }



        stage('Terraform Validate') {

            steps {

                echo "========== TERRAFORM VALIDATE =========="

                sh '''
                terraform validate
                '''

            }

        }

        stage('Terraform Plan') {

            steps {

                script {

                    if (params.DEPLOYMENT_MODE == 'Create / Update Infrastructure') {

                    echo "========== TERRAFORM PLAN =========="

                    sh '''
                    terraform plan -out=tfplan
                    '''

                    } else {

                        echo "========== TERRAFORM DESTROY PLAN =========="

                        sh '''
                        terraform plan -destroy -out=destroy.tfplan
                    '''
                    }
                }
            
            }
        
        }


        stage('Terraform Destroy') {

            when {

                allOf {

                expression {
                params.DEPLOYMENT_MODE == 'Destroy and Rebuild'
                }

                expression {
                env.STATE_EXISTS == 'true'
                }

                }
            }

            steps {

                echo "========== TERRAFORM DESTROY =========="

                sh '''
                terraform apply \
                -auto-approve \
                destroy.tfplan
                '''
            }
        }

        stage('Terraform Apply') {

            steps {

                echo "========== TERRAFORM APPLY =========="

                script {

                    if (params.DEPLOYMENT_MODE == 'Create / Update Infrastructure') {

                        sh '''
                        terraform apply \
                        -auto-approve \
                        tfplan
                        '''

                        } else {

                        sh '''
                        terraform apply \
                        -auto-approve
                        '''
                        }
                    }
           
                }
        
        }

        stage('Ensure EC2 Running & Generate Inventory') {

            when {
                expression {
                    params.DEPLOYMENT_MODE == 'Create / Update Infrastructure'
                }
            }
        

            steps {

                script {

                    sh '''
                    echo "=========================================="
                    echo "CHECKING EC2 INSTANCE"
                    echo "=========================================="

                    INSTANCE_ID=$(terraform output -raw ec2_instance_id)

                    echo "EC2 Instance ID: $INSTANCE_ID"

                    INSTANCE_STATE=$(aws ec2 describe-instances \
                    --instance-ids "$INSTANCE_ID" \
                    --query 'Reservations[0].Instances[0].State.Name' \
                    --output text)

                    echo "Current EC2 State: $INSTANCE_STATE"

                    if [ "$INSTANCE_STATE" = "stopped" ]; then

                    echo "EC2 is stopped."
                    echo "Starting EC2..."

                    aws ec2 start-instances \
                    --instance-ids "$INSTANCE_ID"

                    echo "Waiting for EC2 to become running..."

                    aws ec2 wait instance-running \
                    --instance-ids "$INSTANCE_ID"

                    echo "EC2 is now running."

                    # Give AWS a little time to assign networking
                    sleep 10

                    elif [ "$INSTANCE_STATE" = "running" ]; then

                    echo "EC2 is already running."

                    else

                    echo "ERROR: EC2 is in unexpected state: $INSTANCE_STATE"
                    exit 1

                    fi

                    echo "=========================================="
                    echo "GETTING CURRENT PUBLIC IP"
                    echo "=========================================="

                    EC2_PUBLIC_IP=""

                    for i in $(seq 1 30); do

                    EC2_PUBLIC_IP=$(aws ec2 describe-instances \
                    --instance-ids "$INSTANCE_ID" \
                    --query 'Reservations[0].Instances[0].PublicIpAddress' \
                    --output text)

                    if [ "$EC2_PUBLIC_IP" != "None" ] && [ -n "$EC2_PUBLIC_IP" ]; then
                    break
                    fi

                    echo "Public IP not available yet. Attempt $i/30"
                    sleep 5

                    done

                    if [ -z "$EC2_PUBLIC_IP" ] || [ "$EC2_PUBLIC_IP" = "None" ]; then

                    echo "ERROR: EC2 does not have a public IP."
                    exit 1

                    fi

                    echo "CURRENT EC2 PUBLIC IP: $EC2_PUBLIC_IP"

                    echo "=========================================="
                    echo "CREATING ANSIBLE INVENTORY"
                    echo "=========================================="

                    mkdir -p ansible/inventory

                    cat > ansible/inventory/hosts <<EOF
                    [terraform_servers]
                    $EC2_PUBLIC_IP ansible_user=ubuntu
                    EOF

                    echo "Generated inventory:"

                    cat ansible/inventory/hosts
                    '''

                }

            }
        }
        

        stage('Terraform Outputs') {

            steps {

                echo "========== TERRAFORM OUTPUT =========="

                sh '''
                terraform output
                '''

            }

        }


        stage('Architecture Summary') {
            
            steps {
                echo "========== AWS INFRASTRUCTURE SUMMARY =========="

                sh '''
                echo ""
                echo "=============================================================="
                echo "                AWS TERRAFORM INFRASTRUCTURE"
                echo "=============================================================="

                echo ""
                echo "AWS ACCOUNT"
                aws sts get-caller-identity

                echo ""
                echo "--------------------------------------------------------------"
                echo "NETWORK"
                echo "--------------------------------------------------------------"

                echo "VPC ID              : $(terraform output -raw vpc_id)"
                echo "Public Subnet       : $(terraform output -raw public_subnet_id)"
                echo "Private Subnet      : $(terraform output -raw private_subnet_id)"
                echo "Security Group      : $(terraform output -raw security_group_id)"

                echo ""
                echo "--------------------------------------------------------------"
                echo "EC2 INSTANCE"
                echo "--------------------------------------------------------------"

                INSTANCE_ID=$(terraform output -raw ec2_instance_id)

                aws ec2 describe-instances \
                --instance-ids $INSTANCE_ID \
                --query 'Reservations[0].Instances[0].[
                    InstanceId,
                    InstanceType,
                    State.Name,
                    Placement.AvailabilityZone,
                    PublicIpAddress,
                    PrivateIpAddress,
                    KeyName,
                    PlatformDetails,
                    VpcId,
                    SubnetId,
                    ImageId
                ]' \
                --output table

                echo ""
                echo "--------------------------------------------------------------"
                echo "SECURITY GROUP RULES"
                echo "--------------------------------------------------------------"

                SG=$(terraform output -raw security_group_id)

                aws ec2 describe-security-groups \
                --group-ids $SG \
                --query 'SecurityGroups[0].IpPermissions[*].[FromPort,ToPort,IpProtocol,IpRanges[*].CidrIp]' \
                --output table

                echo ""
                echo "--------------------------------------------------------------"
                echo "IAM"
                echo "--------------------------------------------------------------"

                echo "Instance Profile : $(terraform output -raw instance_profile_name)"

                echo ""
                echo "--------------------------------------------------------------"
                echo "S3"
                echo "--------------------------------------------------------------"

                echo "Terraform Bucket : terraform-state-vansh-2026"
                echo "Backup Bucket    : jenkins-backup-vansh-2026"

                echo ""
                echo "--------------------------------------------------------------"
                echo "REGION"
                echo "--------------------------------------------------------------"

                echo "AWS Region : eu-north-1"

                echo ""
                echo "--------------------------------------------------------------"
                echo "TERRAFORM OUTPUTS"
                echo "--------------------------------------------------------------"

                terraform output

                echo ""
                echo "=============================================================="
                echo "Infrastructure Provisioned Successfully"
                echo "=============================================================="
                '''
            }
        }

        stage('Generate Ansible Inventory') {
            
            when {
                expression {
                params.DEPLOYMENT_MODE == 'Create / Update Infrastructure'
                }
            }

            
            steps {
                
                script {

                    def instanceId = sh(
                    script: "terraform output -raw ec2_instance_id",
                    returnStdout: true
                    ).trim()

                    echo "EC2 Instance ID = ${instanceId}"

                    def instanceState = sh(
                    script: """
                    aws ec2 describe-instances \
                    --instance-ids ${instanceId} \
                    --query 'Reservations[0].Instances[0].State.Name' \
                    --output text
                    """,
                    returnStdout: true
                    ).trim()

                    echo "EC2 State = ${instanceState}"

                    if (instanceState != "running") {
                    error("EC2 is not running. Current state: ${instanceState}")
                }

                def publicIp = sh(
                script: """
                    aws ec2 describe-instances \
                    --instance-ids ${instanceId} \
                    --query 'Reservations[0].Instances[0].PublicIpAddress' \
                    --output text
                    """,
                returnStdout: true
                ).trim()

                echo "EC2 PUBLIC IP = ${publicIp}"

                if (!publicIp || publicIp == "None") {
                error("EC2 is running but does not have a public IP.")
                }

                 env.EC2_PUBLIC_IP = publicIp

                sh """
                mkdir -p ansible/inventory

                cat > ansible/inventory/hosts <<EOF
                [terraform_servers]
                ${publicIp} ansible_user=ubuntu
                EOF
                """

                echo "Inventory Created Successfully"

                sh "cat ansible/inventory/hosts"
            }
            }

        }
    

        stage('Display Inventory') {

            when {
                anyOf {
                    expression { params.DEPLOYMENT_MODE == 'Create / Update Infrastructure' }
                    expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }

            steps {

                echo "========== INVENTORY =========="

                sh '''
                cat ansible/inventory/hosts
                '''
            }
        }

        stage('Run Ansible Playbook') {

            when {
                expression {
                    params.DEPLOYMENT_MODE == 'Create / Update Infrastructure'
                }
            }
            


            steps {

                echo "========== RUNNING ANSIBLE =========="

                sshagent(['agent-key']) {

                sh '''
                INSTANCE_ID=$(terraform output -raw ec2_instance_id)

                echo "EC2 Instance ID = $INSTANCE_ID"

                INSTANCE_STATE=$(aws ec2 describe-instances \
                    --instance-ids "$INSTANCE_ID" \
                    --query 'Reservations[0].Instances[0].State.Name' \
                    --output text)

                echo "EC2 State = $INSTANCE_STATE"

                if [ "$INSTANCE_STATE" != "running" ]; then
                    echo "ERROR: EC2 is not running."
                    exit 1
                fi

                echo "Getting current EC2 public IP..."

                EC2_PUBLIC_IP=$(aws ec2 describe-instances \
                    --instance-ids "$INSTANCE_ID" \
                    --query 'Reservations[0].Instances[0].PublicIpAddress' \
                    --output text)

                echo "EC2 PUBLIC IP = $EC2_PUBLIC_IP"

                if [ -z "$EC2_PUBLIC_IP" ] || [ "$EC2_PUBLIC_IP" = "None" ]; then
                    echo "ERROR: EC2 does not have a public IP."
                    exit 1
                fi

                echo "Updating Ansible inventory..."

                mkdir -p ansible/inventory

                cat > ansible/inventory/hosts <<EOF
                [terraform_servers]
                $EC2_PUBLIC_IP ansible_user=ubuntu
                EOF

                echo "========== INVENTORY =========="
                cat ansible/inventory/hosts

                echo "========== WAITING FOR SSH =========="

                SSH_READY=false

                for i in $(seq 1 30); do

                    if ssh \
                        -o StrictHostKeyChecking=no \
                        -o ConnectTimeout=5 \
                        ubuntu@$EC2_PUBLIC_IP "echo SSH READY" 2>/dev/null
                    then
                        echo "SSH is ready."
                        SSH_READY=true
                        break
                    fi

                    echo "SSH not ready yet. Attempt $i/30"
                    sleep 10

                done

                if [ "$SSH_READY" != "true" ]; then
                    echo "ERROR: SSH did not become ready."
                    exit 1
                fi

                echo "========== RUNNING ANSIBLE =========="

                cd ansible

                export ANSIBLE_CONFIG=$(pwd)/ansible.cfg

                ansible-playbook \
                    -i inventory/hosts \
                    playbooks/site.yml
                '''
                }
            }
        }
        
        
        stage('Verify Java & Docker') {

            when {
                anyOf {
                    expression { params.DEPLOYMENT_MODE == 'Create / Update Infrastructure' }
                    expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }
            
            steps {

                echo "========== VERIFYING SOFTWARE =========="

                sh '''
                cd ansible

                echo "===== JAVA VERSION ====="
                ansible -i inventory/hosts terraform_servers -m shell -a "java -version"

                echo "===== DOCKER VERSION ====="
                ansible -i inventory/hosts terraform_servers -m shell -a "docker --version"

                echo "===== DOCKER STATUS ====="
                ansible -i inventory/hosts terraform_servers -b -m shell -a "docker ps"

                echo "===== DOCKER SERVICE ====="
                ansible -i inventory/hosts terraform_servers -b -m shell -a "systemctl is-active docker"
                '''

            }
        }

        stage('Deploy Docker Application') {

            when {
                anyOf {
                    expression { params.DEPLOYMENT_MODE == 'Create / Update Infrastructure' }
                    expression { params.DEPLOYMENT_MODE == 'Destroy and Rebuild' }
                }
            }

            steps {

                echo "========== DEPLOY APPLICATION =========="

                sshagent(credentials: ['agent-key']) {

                sh '''
                cd ansible

                export ANSIBLE_CONFIG=$PWD/ansible.cfg

                ansible-playbook \
                -i inventory/hosts \
                playbooks/deploy-app.yml
                '''

                }

            }

        }

        stage('Upload Project To S3') {

            steps {

                echo "========== UPLOADING PROJECT TO S3 =========="

                sh '''
                aws s3 cp . s3://jenkins-backup-vansh-devops-2026/terraform-project/ \
                --recursive \
                --exclude ".git/*" \
                --exclude ".terraform/*"
                '''

            }

        }

    }

    post {

        always {

            echo "======================================"
            echo "Pipeline Finished"
            echo "======================================"

        }

        success {

            script {
                    if (params.DEPLOYMENT_MODE == 'Destroy and Rebuild') {

                        echo "Infrastructure Destroyed Successfully"
                        echo "Infrastructure Recreated Successfully"

                    } else {

                        echo "Infrastructure Created / Updated Successfully"

                    }
                       echo "Project Uploaded To S3 Successfully"
 
                    }

                echo "Dynamic Agent Will Be Automatically Terminated By Jenkins EC2 Plugin"

                }

        failure {

            echo "Pipeline Failed"

        }

    }

}