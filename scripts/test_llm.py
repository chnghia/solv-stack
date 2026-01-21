#!/usr/bin/env python3
import requests
import json
import os
import sys
import argparse
from typing import Optional

def test_chat_completion(
    base_url: str,
    api_key: str,
    model: str,
    prompt: str,
    stream: bool = False
):
    url = f"{base_url.rstrip('/')}/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    
    payload = {
        "model": model,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "stream": stream
    }

    print(f"--- Testing LLM API ---")
    print(f"URL: {url}")
    print(f"Model: {model}")
    print(f"Stream: {stream}")
    print(f"Prompt: {prompt}")
    print(f"-----------------------")

    try:
        if stream:
            with requests.post(url, headers=headers, json=payload, stream=True) as response:
                response.raise_for_status()
                print("Response: ", end="", flush=True)
                for line in response.iter_lines():
                    if line:
                        line_str = line.decode('utf-8')
                        if line_str.startswith("data: "):
                            data_str = line_str[6:]
                            if data_str == "[DONE]":
                                break
                            try:
                                data = json.loads(data_str)
                                content = data['choices'][0]['delta'].get('content', '')
                                print(content, end="", flush=True)
                            except json.JSONDecodeError:
                                continue
                print("\n")
        else:
            response = requests.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            content = data['choices'][0]['message']['content']
            print(f"Response: {content}")
            
    except requests.exceptions.RequestException as e:
        print(f"Error: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response body: {e.response.text}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test SOLV Stack LLM API")
    parser.add_argument("--url", default="http://localhost:8080/llm", help="Base URL for LLM API")
    parser.add_argument("--key", default=os.getenv("LITELLM_MASTER_KEY", "sk-solv-stack"), help="LiteLLM API Key")
    parser.add_argument("--model", default=os.getenv("VLLM_MODEL_NAME", "qwen2.5-7b"), help="Model name")
    parser.add_argument("--prompt", default="Slogan cho SOLV Stack là gì? Trả lời ngắn gọn.", help="Prompt to test")
    parser.add_argument("--stream", action="store_true", help="Enable streaming")

    args = parser.parse_args()

    test_chat_completion(
        base_url=args.url,
        api_key=args.key,
        model=args.model,
        prompt=args.prompt,
        stream=args.stream
    )
