# Sample plan: TaskLoop

A small fixture business plan for trying the pipeline end to end. Copy the `plancasting/` folder into an empty git repository and run the stages, or drive them with `scripts/trial-run.sh`, which records duration and token usage per stage into `plancasting/_trial/usage.tsv`.

Stage 0 is interactive. For an unattended trial, pass its answers through `EXTRA_PROMPT`; the block below is the one used for the framework's own trials (Next.js + Convex + WorkOS + Vercel, an AI feature on Claude Sonnet 5.5, manual deployment, placeholders for every credential, no project initialization):

```text
Operator answers for Stage 0 (use these instead of asking; if a question is not covered, choose the conventional default and mark it as an assumption):
- Product type: web application (desktop first, responsive mobile). Team size 1 developer.
- Framework: Next.js (App Router), TypeScript, Tailwind CSS v4, shadcn/ui. Package manager: bun.
- Backend/BaaS: Convex. Auth: WorkOS. Hosting: Vercel (frontend) + Convex cloud (backend). Email: Resend. Payments: Stripe Billing.
- AI: Anthropic Claude via the official @anthropic-ai/sdk, model claude-sonnet-5-5 for extraction and digests, structured outputs for extracted items; refusal handled with server-side fallbacks and a graceful error. No agent framework, no vector DB.
- Multi-tenant: workspace is the tenant boundary; users may belong to several workspaces. Authorization: simple 2-role (admin / member) per workspace.
- Design direction: editorial and calm; fonts Fraunces (display) + Inter Tight (body); deep green dominant with warm sand accents; light and dark mode. Icon library: lucide-react. No logo yet.
- Session Language: English. Locale en-US, UTC timestamps.
- Data retention: 12 months paid / 90 days free; soft delete; GDPR export and deletion.
- Accessibility: WCAG 2.2 AA. Analytics: PostHog. Monitoring: Sentry. CI: GitHub Actions. Developer docs yes, user guide no.
- Deployment: manual. Credentials: write placeholder values (YOUR_*_HERE) into .env.local; do not validate keys.
```

Example:

```bash
mkdir -p ~/trial && cp -R examples/sample-plan/plancasting ~/trial/ && cd ~/trial && git init -q
EXTRA_PROMPT="$(sed -n '/^```text$/,/^```$/p' ~/transmute-framework/examples/sample-plan/README.md | sed '1d;$d')" \
  ~/transmute-framework/scripts/trial-run.sh ~/trial tech-stack brd prd validate-specs scaffold
```

Measured on 2026-10-02 (Claude Opus 5.5, plugin v3.2.0): Stage 0 took 3.6 minutes and 11 turns, producing a 304-line `tech-stack.md` with the Model Specifications table filled from the new derivation rules.
