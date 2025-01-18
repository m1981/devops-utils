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

echo "Keys generated and .sops.yaml created"
echo "IMPORTANT: Add the private key to GitHub Secrets as SOPS_AGE_KEY:"
cat ~/.sops/keys.txt
