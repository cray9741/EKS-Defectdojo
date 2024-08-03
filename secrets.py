import subprocess
import boto3
import base64
import yaml
import os
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def update_kubeconfig(cluster_name, region):
    # Update kubeconfig using AWS CLI
    try:
        subprocess.run(['aws', 'eks', 'update-kubeconfig', '--region', region, '--name', cluster_name], check=True)
        logger.info("Kubeconfig updated successfully.")
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to update kubeconfig: {e}")
        raise

def get_ca_data(cluster_name, region):
    # Get CA data using AWS CLI
    try:
        result = subprocess.run(
            ['aws', 'eks', 'describe-cluster', '--region', region, '--name', cluster_name, '--query', 'cluster.certificateAuthority.data', '--output', 'text'],
            check=True,
            capture_output=True,
            text=True
        )
        ca_data_base64 = result.stdout.strip()
        logger.info("CA data retrieved successfully.")
        return ca_data_base64
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to retrieve CA data: {e}")
        raise

def get_eks_token(cluster_name, region):
    # Get EKS token using AWS CLI
    try:
        result = subprocess.run(
            ['aws', 'eks', 'get-token', '--cluster-name', cluster_name, '--region', region],
            check=True,
            capture_output=True,
            text=True
        )
        token_info = yaml.safe_load(result.stdout)
        token = token_info['status']['token']
        logger.info("Token retrieved successfully.")
        return token
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to retrieve token: {e}")
        raise

def store_in_parameter_store(name, value, description):
    try:
        ssm_client = boto3.client('ssm')
        ssm_client.put_parameter(
            Name=name,
            Value=value,
            Type='SecureString',
            Overwrite=True,
            Description=description
        )
        logger.info(f"Parameter {name} stored successfully.")
    except Exception as e:
        logger.error(f"Failed to store parameter {name}: {e}")
        raise

def input_and_store_secrets():
    secrets = {
        "DOJO_API_KEY": "API key for Dojo",
        "DOJO_URL": "URL for Dojo",
        "GITHUB_API_KEY": "API key for GitHub",
        "JIRA_API_KEY": "API key for Jira",
        "JIRA_URL": "URL for Jira",
        "JIRA_USER": "Username for Jira"
    }

    for secret_name, description in secrets.items():
        secret_value = input(f"Enter value for {secret_name}: ")
        store_in_parameter_store(f"/{secret_name}", secret_value, description)

def generate_kubeconfig_data(cluster_name, server_url, ca_data, token):
    kubeconfig_data = {
        'apiVersion': 'v1',
        'clusters': [{
            'cluster': {
                'certificate-authority-data': ca_data,
                'server': server_url
            },
            'name': f'arn:aws:eks:{region}:{account_id}:cluster/{cluster_name}'
        }],
        'contexts': [{
            'context': {
                'cluster': f'arn:aws:eks:{region}:{account_id}:cluster/{cluster_name}',
                'user': 'eksuser'
            },
            'name': f'arn:aws:eks:{region}:{account_id}:cluster/{cluster_name}'
        }],
        'current-context': f'arn:aws:eks:{region}:{account_id}:cluster/{cluster_name}',
        'kind': 'Config',
        'preferences': {},
        'users': [{
            'name': 'eksuser',
            'user': {
                'token': token
            }
        }]
    }
    return kubeconfig_data

if __name__ == '__main__':
    cluster_name = 'legion-nonprod'
    region = 'us-east-1'
    server_url = 'https://DF9D54465DC4BEEB5B345B5E8F534EFE.gr7.us-east-1.eks.amazonaws.com'
    account_id = '038810797634'

    try:
        update_kubeconfig(cluster_name, region)
        ca_data_base64 = get_ca_data(cluster_name, region)
        token = get_eks_token(cluster_name, region)

        # Print the CA data and token
        print("CA data:", ca_data_base64)
        print("Token:", token)

        # Use the printed CA data and token to store in AWS SSM Parameter Store
        store_in_parameter_store('eksuser_token', token, 'EKS User Token')
        store_in_parameter_store('cluster_certificate_authority_data', ca_data_base64, 'Cluster Certificate Authority Data')

        # Prompt for other secrets and store them
        # input_and_store_secrets()

        kubeconfig_data = generate_kubeconfig_data(cluster_name, server_url, ca_data_base64, token)

        # Print the kubeconfig data
        print(yaml.dump(kubeconfig_data))

    except Exception as e:
        logger.error(f"An error occurred: {e}")
