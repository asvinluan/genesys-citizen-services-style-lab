# Compliance map: Citizen Services-style lab

> **Read this honestly.** Items marked **✓** I confirmed against public sources in October 2026. Everything marked **verify** is stated from general knowledge and must be checked against the current text and the agency's own obligations. This is a design aid, not legal advice, and not a statement that any system complies.

| Rule or framework | What it asks, in plain English | How this lab touches it | Status |
|---|---|---|---|
| **✓ Privacy Act 1988 and the APPs** (including APP 1.7 to 1.9, automated decisions, from 10 December 2026) | Collect only what you need, tell people, protect it, say when a program decides things about them | The function takes a reference number only; the bot takes no identity data; the register entry says the bot makes no decisions; retention is a reviewed variable | Confirmed (privacy regulator guidance, September 2026) |
| **✓ Policy for the responsible use of AI in government, v2.0** (NDA, from 15 December 2025) | Accountable officials, an AI use-case register, impact assessments, a transparency statement | `governance/` has a draft register entry, an impact assessment outline and statement notes | Confirmed |
| **✓ IRAP assessment of Genesys Cloud** | Independent assessment of a cloud service against the Information Security Manual, at a stated classification | Ask Genesys for the current report: its scope, the classification level it covers (published material has said OFFICIAL and PROTECTED at different times), the date, and which regions and features are in scope. Do not quote a level without reading the report | Confirmed that assessments exist; **verify** scope and currency |
| **verify: Information Security Manual (ISM)**, the national cyber agency | The control catalogue that IRAP assesses against: identity, access, logging, encryption, incident response | Roles, MFA, IP allow-list, audit, encryption at rest by the provider. Map the platform to the controls the agency has chosen | Verify the current edition and the agency's control selection |
| **verify: Essential Eight** | Eight baseline mitigation strategies: application control, patching, macros, hardening, restricting admin privileges, patching operating systems, MFA, backups | SaaS means Genesys patches the platform. What is yours: MFA, restricting admin privileges (roles and divisions), and backups (configuration in Git) | Verify the target maturity level |
| **verify: Protective Security Policy Framework (PSPF)** | Governance, information, personnel and physical security for government entities | Need-to-know division, separation of duties, vetted team for the restricted queue (the design assumes vetting; it cannot enforce it) | Verify current requirements |
| **verify: Hosting Certification Framework (NDA)** | Rules about where government data is hosted and who controls it | The org is in the Sydney region. Ask whether the provider and the AI features are certified for the data in scope | Verify |
| **verify: Archives Act 1983** | government records must be kept and disposed of under a records authority | Retention policy with a placeholder; the restricted queue is outside it by design; evidence export described | Verify the records authority that applies |
| **verify: Disability Discrimination Act 1992 and digital accessibility (WCAG 2.2 AA for web)** | Services must be usable by people with disability | Relay and interpreter routes, plain prompts, chat widget testing with assistive technology (not done in the lab) | Verify the standard the agency is held to |
| **verify: Notifiable Data Breaches scheme (Privacy Act, Part IIIC)** | Notify the privacy regulator and affected people of eligible breaches | An incident runbook step: who decides whether it is a data breach. Logging and audit make the facts findable | Verify |
| **verify: Public Governance, Performance and Accountability Act 2013** | Proper use of public resources, risk management | Cost section; improvement ideas aimed at cost per resolved contact | Verify |
| **verify: migration law (visa assistance) and the regulator for migration agents** | Giving visa assistance is regulated; only registered agents and some others may do it | The assistant gives general information only and is told never to advise on a visa. The agents and sponsors line is a separate team for registered agents | Verify |
| **verify: Identity, fraud and scam risk (impersonation of the agency is a known pattern)** | Treat identity as the main control; warn the public about scams | Identity checked by a person, never by the menu or the bot; scam warning in the knowledge base; a wrap-up code and a speech-analytics topic for scam reports | Design choice |
| **verify: Handling of national security and protected information** | Some information is protected at a higher level and must stay with cleared staff | A restricted queue and division as a **stand-in** (not a claim about how any department works). No recording, no transcription, no surge override, excluded from builders, publishers, analysts | Design device |

## Evidence you can show

| Evidence | Where |
|---|---|
| Roles, groups and division exclusions | `terraform/locals.tf` (`roles`, `group_roles`), and the plan output |
| Separation of duties | Roles *Flow Developer* and *Release Manager* |
| Recording and retention rules | `terraform/locals.tf` (`recorded_queue_keys`), `modules/quality` |
| AI rules and test evidence | `terraform/locals.tf` (`ai`), Build Manual Part 6 |
| Sign-in rules | `modules/security`, `envs/hardened.tfvars` |
| Change control | Pull requests, CI, `terraform/tests/plan.tftest.hcl` |
| Secrets hygiene | `tools/check_repo.py`, `.gitignore` |
| Operations | `docs/OPERATIONS-AND-ON-CALL.md`, `scripts/*/08-health-check` |
| AI governance | the other files in `governance/` |
