#!/bin/bash

# Define the namespace
NAMESPACE="traefik"
EXPORT_DIR="traefik_config"

# Create the directory to store the exported files
mkdir -p "$EXPORT_DIR"

# Get all resource types in the namespace
RESOURCE_TYPES=$(kubectl api-resources --verbs=list --namespaced -o name | sort)

echo "Exporting configuration for all resources in the '$NAMESPACE' namespace to '$EXPORT_DIR'..."

# Iterate through each resource type and export the configuration
for RESOURCE_TYPE in $RESOURCE_TYPES; do
  echo "Processing resource type: $RESOURCE_TYPE"
  
  # Get the list of resources of this type in the namespace
  RESOURCES=$(kubectl get "$RESOURCE_TYPE" -n "$NAMESPACE" -o name)
  
  # Iterate through each resource and export it
  for RESOURCE in $RESOURCES; do
    # Extract the resource name
    RESOURCE_NAME=$(echo "$RESOURCE" | cut -d'/' -f2)
    
    # Define the filename
    FILENAME="${EXPORT_DIR}/${RESOURCE_TYPE}-${RESOURCE_NAME}.yaml"
    
    echo "Exporting resource: $RESOURCE to $FILENAME"
    kubectl get "$RESOURCE" -n "$NAMESPACE" -o yaml > "$FILENAME"
  done
done

echo "Done exporting configuration for the '$NAMESPACE' namespace."
