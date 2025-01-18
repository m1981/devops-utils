#!/bin/bash
set -eu

# Create directories
mkdir -p ~/.sops
mkdir -p secrets

# Generate Age key pair
docker run --rm -it \
  -v ~/.sops:/home/developer/.sops \
  age-dev bash -c '
    age-keygen -o ~/.sops/keys.txt
    echo "Public key:"
    cat ~/.sops/keys.txt | grep "public key"
  '

# Create .sops.yaml configuration
cat > .sops.yaml << EOL
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: $(grep "public key:" ~/.sops/keys.txt | cut -d: -f2 | tr -d ' ')
EOL
echo SOPS file created at .sops.yaml
echo "-----------------------------------"
cat .sops.yaml
echo "-----------------------------------"
echo ""
echo "IMPORTANT: Add the private key to GitHub Secrets as SOPS_AGE_KEY:"
echo "-----------------------------------"
cat ~/.sops/keys.txt
echo "-----------------------------------"
