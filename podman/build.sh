#!/bin/bash
# Build script for PostgreSQL 18 container

set -e

IMAGE_NAME="${IMAGE_NAME:-postgresql}"
IMAGE_TAG="${IMAGE_TAG:-18}"
REGISTRY="${REGISTRY:-your-registry.example.com}"  # Set your registry here

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building PostgreSQL 18 container...${NC}"
echo "Image name: ${IMAGE_NAME}"
echo "Image tag: ${IMAGE_TAG}"

# Build the container
if command -v podman &> /dev/null; then
    echo -e "${GREEN}Using Podman to build the container...${NC}"
    podman build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f Containerfile.postgresql .
    
    # Tag for registry if specified
    if [ -n "$REGISTRY" ]; then
        echo -e "${GREEN}Tagging image for registry: ${REGISTRY}${NC}"
        podman tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${YELLOW}To run the container:${NC}"
    echo "  podman run -d --name postgres -e POSTGRES_PASSWORD=mysecret -p 5432:5432 ${IMAGE_NAME}:${IMAGE_TAG}"
    
    if [ -n "$REGISTRY" ]; then
        echo -e "${YELLOW}To push to registry:${NC}"
        echo "  podman push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
elif command -v docker &> /dev/null; then
    echo -e "${GREEN}Using Docker to build the container...${NC}"
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f Containerfile.postgresql .
    
    # Tag for registry if specified
    if [ -n "$REGISTRY" ]; then
        echo -e "${GREEN}Tagging image for registry: ${REGISTRY}${NC}"
        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo -e "${YELLOW}To run the container:${NC}"
    echo "  docker run -d --name postgres -e POSTGRES_PASSWORD=mysecret -p 5432:5432 ${IMAGE_NAME}:${IMAGE_TAG}"
    
    if [ -n "$REGISTRY" ]; then
        echo -e "${YELLOW}To push to registry:${NC}"
        echo "  docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
else
    echo -e "${RED}Error: Neither podman nor docker found in PATH${NC}"
    exit 1
fi
