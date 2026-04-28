#!/usr/bin/env bash
# package.sh — build a release ZIP for submission to the ChurchCRM plugin registry.
#
# Usage:
#   bash scripts/package.sh
#
# Output:
#   dist/<id>-<version>.zip   ready-to-attach release artifact
#   SHA-256 printed to stdout for pasting into approved-plugins.json
#
# The zip is structured as  <id>/<files>  so the CRM installer can unpack it
# directly into  src/plugins/community/<id>/  without any extra path munging.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON="$REPO_ROOT/plugin.json"

if [[ ! -f "$PLUGIN_JSON" ]]; then
  echo "Error: plugin.json not found at $PLUGIN_JSON" >&2
  exit 1
fi

# Read id and version from plugin.json (requires jq or python3)
if command -v jq &>/dev/null; then
  PLUGIN_ID="$(jq -r '.id' "$PLUGIN_JSON")"
  PLUGIN_VERSION="$(jq -r '.version' "$PLUGIN_JSON")"
  PLUGIN_NAME="$(jq -r '.name // empty' "$PLUGIN_JSON")"
  PLUGIN_AUTHOR="$(jq -r '.author // empty' "$PLUGIN_JSON")"
  PLUGIN_MIN_CRM="$(jq -r '.minimumCRMVersion // "7.1.0"' "$PLUGIN_JSON")"
elif command -v python3 &>/dev/null; then
  PLUGIN_ID="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d['id'])")"
  PLUGIN_VERSION="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d['version'])")"
  PLUGIN_NAME="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('name',''))")"
  PLUGIN_AUTHOR="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('author',''))")"
  PLUGIN_MIN_CRM="$(python3 -c "import json; d=json.load(open('$PLUGIN_JSON')); print(d.get('minimumCRMVersion','7.1.0'))")"
else
  echo "Error: jq or python3 is required to read plugin.json" >&2
  exit 1
fi

DIST_DIR="$REPO_ROOT/dist"
mkdir -p "$DIST_DIR"

ZIP_NAME="${PLUGIN_ID}-${PLUGIN_VERSION}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

rm -f "$ZIP_PATH"

# Build zip from a temp staging directory so the top-level folder inside the
# archive is named after the plugin id (as required by the CRM installer).
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

PLUGIN_STAGING="$STAGING/$PLUGIN_ID"
mkdir "$PLUGIN_STAGING"

# Copy everything except development-only artifacts and hidden files.
# The CRM installer rejects hidden files (dotfiles) other than .editorconfig
# and .gitattributes, so exclude all of them to avoid install errors.
rsync -a --exclude='.*' \
         --exclude='dist' \
         --exclude='scripts' \
         --exclude='node_modules' \
         "$REPO_ROOT/" "$PLUGIN_STAGING/"

cd "$STAGING"
zip -r "$ZIP_PATH" "$PLUGIN_ID" -x "*.DS_Store"
cd "$REPO_ROOT"

# Compute SHA-256
if command -v shasum &>/dev/null; then
  SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
elif command -v sha256sum &>/dev/null; then
  SHA256="$(sha256sum "$ZIP_PATH" | awk '{print $1}')"
else
  echo "Error: shasum or sha256sum is required" >&2
  exit 1
fi

echo ""
echo "Plugin packaged successfully"
echo "------------------------------"
echo "  File    : $ZIP_PATH"
echo "  SHA-256 : $SHA256"
echo ""
echo "Paste into approved-plugins.json:"
echo ""
cat <<JSON
{
  "id": "$PLUGIN_ID",
  "name": "$PLUGIN_NAME",
  "version": "$PLUGIN_VERSION",
  "downloadUrl": "https://github.com/YOUR_ORG/YOUR_REPO/releases/download/v${PLUGIN_VERSION}/${ZIP_NAME}",
  "sha256": "$SHA256",
  "risk": "low",
  "riskSummary": "TODO: one sentence describing the worst capability this plugin exercises.",
  "permissions": [],
  "minimumCRMVersion": "$PLUGIN_MIN_CRM",
  "author": "$PLUGIN_AUTHOR",
  "reviewedAt": "$(date +%Y-%m-%d)"
}
JSON
echo ""
echo "Next steps:"
echo "  1. Tag this commit:  git tag v${PLUGIN_VERSION} && git push origin v${PLUGIN_VERSION}"
echo "  2. Create a GitHub Release and attach $ZIP_NAME from the dist/ folder"
echo "  3. Replace the downloadUrl placeholder above with the real GitHub release URL"
echo "  4. Open a PR against ChurchCRM/CRM updating src/plugins/approved-plugins.json"
