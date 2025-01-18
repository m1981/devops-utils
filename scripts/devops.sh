#!/bin/bash
set -euo pipefail

# Constants
readonly DOCKER_IMAGE="age-dev"
readonly DOCKER_BUILD_DIR="docker/age-sops"
readonly SOPS_DIR="${HOME}/.sops"
readonly KEYS_FILE="${SOPS_DIR}/keys.txt"
readonly SOPS_CONFIG=".sops.yaml"
readonly SECRETS_DIR="secrets"
# Add path to the devops-utils installation directory
readonly DEVOPS_UTILS_DIR="${HOME}/.devops-utils"

# Get the script name without path for help display
readonly SCRIPT_NAME=$(basename "$0")

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Helper functions
log_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}$1${NC}"
}

log_info() {
    echo -e "${BLUE}$1${NC}"
}

show_help() {
    echo "Usage: ${SCRIPT_NAME} <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  build-image              Build the Docker image"
    echo "  generate-keys            Generate new Age keys and create .sops.yaml"
    echo "  encrypt <file.yaml>      Encrypt the specified YAML file"
    echo "  decrypt <file.enc.yaml>  Decrypt the specified encrypted YAML file"
    echo "  devops-shell             Start a devops shell session with the environment setup"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  ${SCRIPT_NAME} build-image"
    echo "  ${SCRIPT_NAME} generate-keys"
    echo "  ${SCRIPT_NAME} encrypt secrets/dev.yaml"
    echo "  ${SCRIPT_NAME} decrypt secrets/dev.enc.yaml"
}

build_image() {
    log_info "Building Docker image ${DOCKER_IMAGE}..."

    # Get host user's UID and GID
    HOST_UID=$(id -u)
    HOST_GID=$(id -g)

    # Build the Docker image
    docker build \
        --build-arg USER_ID="$HOST_UID" \
        --build-arg GROUP_ID="$HOST_GID" \
        -t "$DOCKER_IMAGE" "${DEVOPS_UTILS_DIR}/docker/age-sops"

    log_success "Successfully built Docker image ${DOCKER_IMAGE}."
}

check_prerequisites() {
    if [ ! -f "$SOPS_CONFIG" ]; then
        log_error ".sops.yaml configuration file not found!"
        log_info "Please run with 'generate-keys' command first"
        exit 1
    fi

    if [ ! -f "$KEYS_FILE" ]; then
        log_error "Age keys not found in ~/.sops/keys.txt"
        log_info "Please run with 'generate-keys' command first"
        exit 1
    fi
}

generate_keys() {
    # Create directories
    mkdir -p "$SOPS_DIR"
    mkdir -p "$SECRETS_DIR"

    # Generate Age key pair
    docker run --rm -it \
        -v "${SOPS_DIR}:/home/developer/.sops" \
        "$DOCKER_IMAGE" bash -c '
            age-keygen -o ~/.sops/keys.txt
            echo "Public key:"
            grep "public key" ~/.sops/keys.txt
        '

    # Create .sops.yaml configuration
    local public_key
    public_key=$(grep "public key:" "$KEYS_FILE" | cut -d: -f2 | tr -d ' ')

    cat > "$SOPS_CONFIG" << EOL
creation_rules:
  - path_regex: secrets/.*\.ya?ml\$
    age: ${public_key}
EOL

    log_success "SOPS file created at $SOPS_CONFIG"
    echo "-----------------------------------"
    cat "$SOPS_CONFIG"
    echo "-----------------------------------"
    echo ""
    log_info "IMPORTANT: Add the private key to GitHub Secrets as SOPS_AGE_KEY:"
    echo "-----------------------------------"
    cat "$KEYS_FILE"
    echo "-----------------------------------"
}

encrypt_file() {
    local input_file="$1"
    local output_file="${input_file%.yaml}.enc.yaml"

    # Check if input file exists
    if [ ! -f "$input_file" ]; then
        log_error "Input file does not exist: $input_file"
        return 1
    fi

    check_prerequisites

    docker run --rm \
        -v "$(pwd):/work" \
        -v "${SOPS_DIR}:/home/developer/.sops" \
        -w /work \
        -e SOPS_AGE_KEY_FILE=/home/developer/.sops/keys.txt \
        "$DOCKER_IMAGE" bash -c "sops --encrypt '$input_file' > '$output_file'"

    log_success "Successfully encrypted: $output_file"
}

decrypt_file() {
    local input_file="$1"
    local output_file="${input_file%.enc.yaml}.yaml"

    check_prerequisites

    docker run --rm \
        -v "$(pwd):/work" \
        -v "${SOPS_DIR}:/home/developer/.sops" \
        -w /work \
        -e SOPS_AGE_KEY_FILE=/home/developer/.sops/keys.txt \
        "$DOCKER_IMAGE" bash -c "sops --decrypt '$input_file' > '$output_file'"

    log_success "Successfully decrypted: $output_file"
}

devops_shell() {
    check_prerequisites

    docker run --rm -it \
        -v "$(pwd):/work" \
        -v "${SOPS_DIR}:/home/developer/.sops" \
        -w /work \
        -e SOPS_AGE_KEY_FILE=/home/developer/.sops/keys.txt \
        "$DOCKER_IMAGE" bash
}

show_help() {
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  build-image              Build the Docker image"
    echo "  generate-keys            Generate new Age keys and create .sops.yaml"
    echo "  encrypt <file.yaml>      Encrypt the specified YAML file"
    echo "  decrypt <file.enc.yaml>  Decrypt the specified encrypted YAML file"
    echo "  devops-shell             Start a devops shell session with the environment setup"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build-image"
    echo "  $0 generate-keys"
    echo "  $0 encrypt secrets/dev.yaml"
    echo "  $0 decrypt secrets/dev.enc.yaml"
}

# Main script
case "${1:-help}" in
    build-image)
        build_image
        ;;
    generate-keys)
        generate_keys
        ;;
    encrypt)
        if [ $# -ne 2 ]; then
            log_error "Encryption requires a file argument."
            show_help
            exit 1
        fi
        encrypt_file "$2"
        ;;
    decrypt)
        if [ $# -ne 2 ]; then
            log_error "Decryption requires a file argument."
            show_help
            exit 1
        fi
        decrypt_file "$2"
        ;;
    devops-shell)
        devops_shell
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: ${1:-}"
        show_help
        exit 1
        ;;
esac
