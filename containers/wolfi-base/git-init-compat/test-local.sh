#!/bin/bash
set -e

IMAGE_NAME="git-init-compat:test"
TEST_DIR="/tmp/git-init-tests"

echo "🧪 Starting git-init compatibility tests..."
echo "========================================="

# Clean up test directory
rm -rf $TEST_DIR
mkdir -p $TEST_DIR

# Test 1: Basic clone
echo -e "\n📝 Test 1: Basic git clone"
docker run --rm -v $TEST_DIR:/workspace $IMAGE_NAME \
  -url=https://github.com/octocat/Hello-World \
  -path=/workspace/test1 \

if [ -d "$TEST_DIR/test1/.git" ]; then
  echo "✅ Test 1 PASSED: Repository cloned successfully"
else
  echo "❌ Test 1 FAILED: Repository not cloned"
  exit 1
fi

# Test 2: Clone with specific revision
echo -e "\n📝 Test 2: Clone with specific revision"
docker run --rm -v $TEST_DIR:/workspace $IMAGE_NAME \
  -url=https://github.com/octocat/Hello-World \
  -path=/workspace/test2 \
  -revision=7fd1a60b01f91b314f59955a4e4d4e80d8edf11d \

cd $TEST_DIR/test2
CURRENT_SHA=$(git rev-parse HEAD)
if [ "$CURRENT_SHA" = "7fd1a60b01f91b314f59955a4e4d4e80d8edf11d" ]; then
  echo "✅ Test 2 PASSED: Correct revision checked out"
else
  echo "❌ Test 2 FAILED: Wrong revision. Expected 7fd1a60, got $CURRENT_SHA"
  exit 1
fi
cd - > /dev/null

# Test 3: Shallow clone with depth
echo -e "\n📝 Test 3: Shallow clone with depth=1"
docker run --rm -v $TEST_DIR:/workspace $IMAGE_NAME \
  -url=https://github.com/octocat/Hello-World \
  -path=/workspace/test3 \
  -depth=1 \

cd $TEST_DIR/test3
COMMIT_COUNT=$(git rev-list --count HEAD)
if [ "$COMMIT_COUNT" -eq 1 ]; then
  echo "✅ Test 3 PASSED: Shallow clone with depth=1"
else
  echo "❌ Test 3 FAILED: Expected 1 commit, got $COMMIT_COUNT"
  exit 1
fi
cd - > /dev/null

# Test 4: Clone into existing directory (git will fail if non-empty)
echo -e "\n📝 Test 4: Clone into new subdirectory"
docker run --rm -v $TEST_DIR:/workspace $IMAGE_NAME \
  -url=https://github.com/octocat/Hello-World \
  -path=/workspace/test4 \

if [ -d "$TEST_DIR/test4/.git" ]; then
  echo "✅ Test 4 PASSED: Cloned successfully"
else
  echo "❌ Test 4 FAILED: Failed to clone"
  exit 1
fi

# Test 5: Test with invalid URL (error handling)
echo -e "\n📝 Test 5: Error handling with invalid URL"
docker run --rm -v $TEST_DIR:/workspace $IMAGE_NAME \
  -url=https://github.com/nonexistent/repo-that-does-not-exist \
  -path=/workspace/test5 \
  -verbose=true 2>&1 | grep -q "Failed to clone" && echo "✅ Test 5 PASSED: Error handled correctly" || echo "❌ Test 5 FAILED: Error not handled"

# Test 6: Test SSL verify false
echo -e "\n📝 Test 6: SSL verify disabled"
docker run --rm -v $TEST_DIR:/workspace $IMAGE_NAME \
  -url=https://github.com/octocat/Hello-World \
  -path=/workspace/test6 \
  -sslVerify=false \

if [ -d "$TEST_DIR/test6/.git" ]; then
  echo "✅ Test 6 PASSED: SSL verify disabled worked"
else
  echo "❌ Test 6 FAILED: SSL verify disabled failed"
  exit 1
fi

echo -e "\n========================================="
echo "🎉 All tests completed successfully!"
echo "========================================="

# Clean up
rm -rf $TEST_DIR