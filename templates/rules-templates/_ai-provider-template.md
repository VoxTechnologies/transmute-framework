---
description: Template for LLM/AI-provider call rules — current Claude API request shapes, stop-reason handling, fallbacks, and the parameters that return 400 on current models. Generated only when tech-stack.md lists an AI provider.
paths: ["[AI_DIR]/**", "[BACKEND_DIR]/**/*ai*", "[BACKEND_DIR]/**/*llm*"]
---

<!-- Cross-template sync: [ERROR_TYPE] must match .claude/rules/backend.md § Error Handling. The retry policy here extends backend.md § External API Calls — it adds the stop_reason branch that status-code retries miss. -->

# AI Provider Rules

Rules for every call to an LLM API. Model APIs change between generations faster than any other dependency in this codebase, and the request shape you remember from training data is the one most likely to be rejected. Write these calls from the provider's current documentation (`context7` or the official SDK README), never from memory. The rules below are written for the Claude API; adapt the parameter names if `plancasting/tech-stack.md` names a different provider, but keep every rule's intent.

## Client and model

- Use the official SDK ([AI_SDK], e.g. `@anthropic-ai/sdk`). No raw `fetch` to the provider, no OpenAI-compatible shims.
- The model ID comes from one place: `process.env.[AI_MODEL_ENV]` with the default `[AI_MODEL_ID]` from `plancasting/tech-stack.md` § Specifications. Current Claude IDs carry no date suffix (`claude-opus-5-5`, `claude-sonnet-5-5`, `claude-fable-5-1`); only `claude-haiku-4-5` has a dated full form. Never construct an ID by appending a date.
- Stream any request whose `max_tokens` exceeds about 16,000; non-streaming requests that large hit HTTP timeouts.

## Request shape (what returns 400 on current Claude models)

| Do not send | Send instead |
|---|---|
| `thinking: { type: "enabled", budget_tokens: N }` | `thinking: { type: "adaptive" }` or omit `thinking` (adaptive is the default). Depth is controlled with `output_config: { effort: "low" \| "medium" \| "high" \| "xhigh" }` |
| `thinking: { type: "disabled" }` | Omit `thinking` and lower `effort`. Thinking cannot be disabled on Opus 5.5 or Fable 5.1; on Sonnet 5.5 use `thinking: { type: "between_tools" }` only where a route must stay thinking-off |
| A trailing `assistant` message as a prefill (`{ role: "assistant", content: "{" }`) | `output_config: { format: { type: "json_schema", schema } }` (structured outputs) or a system-prompt instruction |
| `output_format: {...}` | `output_config: { format: {...} }` |
| `tool_choice: { type: "any" }` / `{ type: "tool", name }` | `tool_choice: { type: "auto" }` plus a prompt instruction naming the tool, with `strict: true` on the tool definition for schema-valid arguments |
| Non-default `temperature`, `top_p`, `top_k` | Omit them |

`max_tokens` is a hard limit on thinking plus the reply. Size it for both: at least 4,096 for short structured answers, 16,000 or more for prose and code.

## Response handling

- Branch on `stop_reason` before reading `content`. `"refusal"` arrives as HTTP 200 with empty or partial `content` and a `stop_details.category` (`cyber`, `bio`, `reasoning_extraction`, `frontier_llm`, `general_harms`). Treat it as a distinct outcome: no retry on the same model, show the user a [ERROR_TYPE] with a plain explanation, log the category.
- `"max_tokens"` means the reply was cut off: raise `max_tokens` or shorten the input, do not parse the partial text.
- Read content blocks by `type` (`text`, `tool_use`, `thinking`); never assume `content[0]` is text.
- Parse tool inputs with `JSON.parse` from `tool_use.input`; never string-match the serialized input.

## Fallbacks and retries

- Opt into server-side fallback on every request: `betas: ["server-side-fallback-2026-07-01"]` with `fallbacks: "default"`, so a safety-classifier false positive routes to the model Anthropic recommends for that category instead of failing the feature.
- Retry only transport and capacity errors: connection errors, 5xx, and 429 (honor `retry-after`). The backoff policy is in `.claude/rules/backend.md` § External API Calls. A `refusal` or a 400 is never retried as-is.
- Catch a chain of typed SDK errors (`NotFoundError` → `RateLimitError` → `APIStatusError` → `APIConnectionError`), not one broad class, so retryable and non-retryable failures stay distinguishable.

## Conversation history

- Append-only. Pass `thinking` blocks back unchanged on the same model; never edit, reorder, or delete earlier turns. Editing history invalidates the model's preserved thinking and can return 400 on accounts created after 2026-08-31.
- For operator instructions added mid-conversation, append `{ role: "system", content }` to `messages` instead of changing the top-level `system` (keeps the prompt cache).
- Keep stable content (system prompt, tool list) first and volatile content (timestamps, user data) last; put `cache_control: { type: "ephemeral" }` on the last stable block.

## Data handling

- Never log full prompts or completions that may contain user data; log request IDs, `stop_reason`, token usage and latency.
- Fable 5.1 requires 30-day data retention on the organization (zero-data-retention organizations receive 400). Record the retention setting in `plancasting/tech-stack.md` if the product uses it.

## Testing

- Unit tests mock the SDK client, so they cannot catch a rejected request shape. Keep one integration test behind `[AI_INTEGRATION_TEST_ENV]` that sends a real minimal request (`max_tokens: 16`) and asserts on HTTP success, not on the reply text.
- Stage 7V Check 11.1 greps this codebase for the rejected parameters listed above; a match blocks launch.
