---
name: ai-llm-router
description: Signal table for AI/LLM/agent security hunting -- prompt injection, jailbreak, excessive agency, RAG poisoning.
---

# AI & LLM Security Hunting — Router

> [!NOTE]
> LLM vulnerabilities only pay when chained to concrete, demonstrable impact (data exfiltration, cross-session/cross-tenant access, unauthorized tool-calling/state mutation, or SSRF). Hallucinations, generic offensive text generation in sandboxes, and self-contained conversational quirks are not valid findings.

Scan this router when testing applications integrating Large Language Models (LLMs), AI conversational assistants, autonomous agents with tool-calling capabilities, or RAG/vector-search knowledge pipelines.

---

## AI & LLM Signal Table

| Feature / Surface Shape | Observable Signals (UI, API, Params, Headers) | How to Confirm (Behavioral / Differential Proof) | Reference File |
|---|---|---|---|
| **Direct Prompt Injection** | Chat inputs, message forms, document summarization, translate features | Inject delimiter override (`\n\nSystem: Ignore previous...`); confirm model executes hidden instruction to emit canary or call tool | `references/prompt-injection.md` |
| **Indirect / Stored Injection** | Web page summaries, email ingestion, ticket parsing, document upload, third-party webhook feeds | Ingest text containing embedded instruction; verify separate user session or autonomous agent executes payload | `references/prompt-injection.md` |
| **Jailbreak / Policy Bypass** | Guardrail/moderation filters, refused topics, safety filters (`400 Bad Request: Policy Violation`) | Use hypotheticals, persona framing, or token obfuscation; confirm model generates restricted/policy-violating output | `references/jailbreak.md` |
| **System Prompt Leak** | AI chatbot with internal instructions, system prompts, hidden tools catalog, persona rules | Ask model to repeat words above, translate previous text, or output starting with ````json`; verify raw system prompt leaks | `references/system-prompt-leak.md` |
| **Excessive Agency & Tool Abuse**| Agent with tool-calling (`search_web`, `send_email`, `execute_sql`, `run_code`, `fetch_url`), autonomous actions | Prompt agent to invoke sensitive tool with attacker-controlled arguments (`send_email(to="attacker", body=secret)`); verify tool execution | `references/excessive-agency.md` |
| **Cross-Tenant Vector IDOR** | Knowledge bases, document search, RAG queries, `/api/knowledge/`, `/similar`, `/embeddings/` | Pass manipulate `namespace` or document ID in search; confirm returned chunks contain verified data from another tenant | `references/rag-vector.md` |
| **Persistent Corpus Poisoning** | Uploading documents/files to shared or public knowledge bases, vector indexing pipelines | Upload chunk with hidden trigger; verify clean, unrelated user session retrieves poisoned chunk on common topic query | `references/rag-vector.md` |
| **Unauthenticated Vector DB** | Direct ports exposed (Chroma `:8000`, Qdrant `:6333`, Weaviate `:8080`, Milvus `:19530`, Pinecone keys) | Send `GET /collections` or `POST /v1/graphql`; verify unauthenticated full vector/text database dump | `references/rag-vector.md` |
