#!/bin/bash

# Default values
BASE_URL=${1:-"http://localhost:8080"}
API_KEY=${LITELLM_MASTER_KEY:-"sk-solv-stack"}
MODEL_NAME=${VLLM_MODEL_NAME:-"qwen2.5-7b"}

echo "------------------------------------------------"
echo "SOLV STACK - QUICK API SANITY CHECK"
echo "Base URL: $BASE_URL"
echo "------------------------------------------------"

# 1. Check Proxied Services Health
echo -n "[1/4] Nginx Proxy Health: "
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/llm/health/liveliness"
echo ""

echo -n "[2/4] LiteLLM Health: "
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/llm/health/liveliness"
echo ""

echo -n "[3/4] Qdrant Health: "
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/qdrant/readyz"
echo ""

echo -n "[4/4] SearXNG Health: "
curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/search/"
echo ""

echo "------------------------------------------------"
echo "TESTING LLM CHAT COMPLETION"
echo "------------------------------------------------"

curl -X POST "$BASE_URL/llm/chat/completions" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $API_KEY" \
     -d "{
       \"model\": \"$MODEL_NAME\",
       \"messages\": [{\"role\": \"user\", \"content\": \"Hello, what is SOLV Stack?\"}],
       \"max_tokens\": 50
     }"

echo -e "\n------------------------------------------------"
echo "Done."
