
#!/usr/bin/env bash
# Generate new feature on demand

read -rp "Feature name: " FEATURE_NAME
read -rp "State management (bloc/riverpod/provider/getx): " STATE_MGMT

./scripts/setup-unix.sh \
  --add-feature "$FEATURE_NAME" \
  --state "$STATE_MGMT" \
  --skip-install
