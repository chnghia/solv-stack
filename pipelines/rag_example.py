"""
SOLV Stack - Example RAG Pipeline
Middleware để inject context từ Qdrant vào LLM request
"""
from typing import Optional, List
import requests
import json

# Pipeline metadata for OpenWebUI
name = "RAG Context Injector"
description = "Enrich prompts with relevant context from Qdrant vector database"
version = "1.0.0"


class Pipeline:
    """
    Pipeline xử lý RAG trước khi gửi request đến LLM.
    
    Flow:
    1. User gửi message
    2. Pipeline convert message thành embedding
    3. Query Qdrant để lấy relevant documents
    4. Inject documents vào system prompt
    5. Forward request đến LiteLLM
    """
    
    def __init__(self):
        # Config endpoints
        self.qdrant_url = "http://qdrant:6333"
        self.litellm_url = "http://litellm:4000"
        
        # Config RAG
        self.collection_name = "documents"
        self.top_k = 5
        self.score_threshold = 0.7
    
    async def on_startup(self):
        """Called when pipeline starts"""
        print(f"[{name}] Pipeline started - Qdrant: {self.qdrant_url}")
    
    async def on_shutdown(self):
        """Called when pipeline stops"""
        print(f"[{name}] Pipeline stopped")
    
    def search_context(self, query: str) -> List[dict]:
        """
        Search relevant documents from Qdrant
        
        Args:
            query: User's question/message
            
        Returns:
            List of relevant document chunks
        """
        try:
            # TODO: Implement embedding via LiteLLM
            # response = requests.post(
            #     f"{self.litellm_url}/embeddings",
            #     json={
            #         "model": "text-embedding-3-small",
            #         "input": query
            #     }
            # )
            # embedding = response.json()["data"][0]["embedding"]
            
            # TODO: Query Qdrant with embedding
            # results = requests.post(
            #     f"{self.qdrant_url}/collections/{self.collection_name}/points/search",
            #     json={
            #         "vector": embedding,
            #         "top": self.top_k,
            #         "score_threshold": self.score_threshold
            #     }
            # )
            
            return []  # Placeholder
            
        except Exception as e:
            print(f"[{name}] Search error: {e}")
            return []
    
    def pipe(
        self,
        user_message: str,
        model_id: str,
        messages: List[dict],
        body: dict
    ) -> dict:
        """
        Main pipeline entry point
        
        Args:
            user_message: Latest user message
            model_id: Target model name
            messages: Full conversation history
            body: Original request body
            
        Returns:
            Modified request body with injected context
        """
        
        # Search for relevant context
        context_docs = self.search_context(user_message)
        
        if context_docs:
            # Build context string
            context_str = "\n\n".join([
                f"[Document {i+1}]\n{doc.get('content', '')}"
                for i, doc in enumerate(context_docs)
            ])
            
            # Inject into system message
            rag_system_prompt = f"""You have access to the following relevant documents:

<context>
{context_str}
</context>

Use this context to answer the user's question accurately. If the context doesn't contain relevant information, say so."""
            
            # Prepend to messages
            if messages and messages[0].get("role") == "system":
                messages[0]["content"] = rag_system_prompt + "\n\n" + messages[0]["content"]
            else:
                messages.insert(0, {"role": "system", "content": rag_system_prompt})
        
        # Update body with modified messages
        body["messages"] = messages
        
        return body
