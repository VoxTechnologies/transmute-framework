# TaskLoop — Business Plan (sample fixture)

This is the fixture business plan used by `scripts/conformance.sh`. It is deliberately small, but it touches every category Stage 0 extracts (product type, users, features, billing, AI, multi-tenancy, compliance, integrations) so that a run of Stages 0–3 exercises every branch of the pipeline, including the AI-provider rules template.

## 1. Product

TaskLoop is a web application for small consulting teams (3–30 people) that turns meeting notes into tracked tasks. A team member pastes or uploads meeting notes; TaskLoop extracts action items with an LLM, proposes owners and due dates from the team roster, and files them as tasks the team manages on a board. Every task keeps a link back to the sentence in the notes it came from.

## 2. Target users and personas

- **Team lead (Maya)** — runs weekly client meetings, wants action items captured without typing them twice, and needs a weekly digest per client.
- **Consultant (Dev)** — works across 2–3 clients, wants a single board of their own tasks across workspaces, and a mobile-friendly view.
- **Workspace admin (Priya)** — manages members, billing, and data retention for the firm.

## 3. Features

All features ship in the first release; the priority sets build order, not scope.

| ID | Feature | Priority |
|---|---|---|
| F1 | Workspace and member management (invite by email, roles: admin / member) | P0 |
| F2 | Meeting note capture: paste text or upload `.md` / `.txt` / `.docx` | P0 |
| F3 | AI action-item extraction with owner and due-date suggestions; every item links to its source sentence | P0 |
| F4 | Task board (list and kanban), per-workspace, with filters by owner, client, due date | P0 |
| F5 | Personal cross-workspace "My tasks" view | P1 |
| F6 | Weekly digest email per client (summary of open, done, overdue) | P1 |
| F7 | Client records (name, contacts, active engagements) that tasks and notes attach to | P1 |
| F8 | Billing: workspace subscription with a free tier (1 workspace, 5 members) and a paid tier (unlimited members, digest emails, 12-month retention) | P2 |
| F9 | Audit log of task changes and member actions, exportable as CSV | P2 |
| F10 | Public API with API keys for reading tasks and creating notes | P3 |

## 4. Business model

Subscription per workspace: free tier and a paid tier at about 4,000 yen per month per workspace. Payment by card through a payment provider. No usage-based pricing in the first release, but AI extraction volume is metered internally so a usage tier can be added later.

## 5. Technical notes

- Web application; desktop first with a responsive mobile layout. No native apps.
- Multi-tenant: the workspace is the tenant boundary. A consultant can belong to several workspaces.
- AI: one LLM provider for extraction and digest drafting; structured output (JSON) for extracted items; a fallback path when the model declines or errors so note capture never fails.
- Integrations: transactional email for invites and digests; payment provider for subscriptions; `.docx` parsing for uploads.
- Data: notes and tasks retained for 12 months on the paid tier and 90 days on the free tier; deletion on workspace closure within 30 days.
- Compliance: personal data of named people in notes; GDPR-style export and deletion requests must be supported for workspace admins.
- Accessibility: WCAG 2.2 AA.
- Language: English UI in the first release; strings externalized so Japanese can follow.

## 6. Non-goals

No calendar sync, no chat integration, no on-premise deployment in the first release.
