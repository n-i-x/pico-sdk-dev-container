#!/bin/bash
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <SDK_VERSION>"
    echo "Example: $0 1.5.1"
    exit 1
fi

SDK_VERSION="$1"

# Validate version format (basic check for x.y.z)
if ! [[ "$SDK_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format x.y.z (e.g., 1.5.1)"
    exit 1
fi

echo "Updating Pico SDK to version $SDK_VERSION..."

# Update Dockerfile
sed -i.bak "s/ENV PICO_SDK_VERSION=.*/ENV PICO_SDK_VERSION=$SDK_VERSION/" Dockerfile
rm -f Dockerfile.bak

echo "✓ Updated Dockerfile"

# Add entry to README.md table
# Find the line with the table header and insert after the last existing entry
TABLE_ENTRY="| $SDK_VERSION | \`ghcr.io/n-i-x/pico-sdk-dev-container:$SDK_VERSION\` | [Release $SDK_VERSION](https://github.com/raspberrypi/pico-sdk/releases/tag/$SDK_VERSION) |"

# Check if entry already exists
if grep -q "$SDK_VERSION" README.md; then
    echo "⚠ Version $SDK_VERSION already exists in README.md, skipping table update"
else
    # Insert new row after the table header separator (second line of table)
    awk -v entry="$TABLE_ENTRY" '
        /^\|[-]+\|[-]+\|[-]+\|$/ && !inserted {
            print $0
            print entry
            inserted = 1
            next
        }
        { print }
    ' README.md > README.md.tmp
    mv README.md.tmp README.md
    echo "✓ Updated README.md"
fi

# Git operations
echo "Committing changes..."
git add Dockerfile README.md
git commit -m "Update Pico SDK to version $SDK_VERSION"

echo "Creating and pushing tag v$SDK_VERSION..."
git tag "v$SDK_VERSION"

echo "Pushing changes and tag to remote..."
git push origin main
git push origin "v$SDK_VERSION"

echo "✅ Successfully updated to Pico SDK $SDK_VERSION"
echo "GitHub Actions will now build and publish the Docker image."
echo "Once complete, it will be available at:"
echo "  - ghcr.io/n-i-x/pico-sdk-dev-container:latest"
echo "  - ghcr.io/n-i-x/pico-sdk-dev-container:$SDK_VERSION"
echo "  - ghcr.io/n-i-x/pico-sdk-dev-container:${SDK_VERSION%.*}"
echo "  - ghcr.io/n-i-x/pico-sdk-dev-container:${SDK_VERSION%%.*}"
