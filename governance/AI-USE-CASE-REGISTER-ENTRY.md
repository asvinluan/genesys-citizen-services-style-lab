# Draft AI use-case register entry: Citizen Services-style lab virtual assistant

> **DRAFT TEMPLATE FOR A LAB.** This is an example of the information an agency would hold in its AI use-case register under the national *Policy for the responsible use of AI in government* (version 2.0, effective 15 December 2025; confirm the current text). Fields in [square brackets] are for the real agency to complete. The lab does not claim any of this has been approved by anyone.

| Field | Entry |
|---|---|
| **Use case name** | Information assistant on the Citizen Services-style contact line and web chat (lab) |
| **Accountable official** | [Name and role. Must be a named person, not a team] |
| **Business owner** | [Contact centre service owner] |
| **Technical owner** | [Platform architect] |
| **Status** | Lab design. Not in production |
| **Purpose** | Give general information from approved content: opening hours, what to have ready, how to authorise another person or give consent, how to get an interpreter or relay, how to complain. Hand off to a person for everything else |
| **What it does not do** | It does not say whether an application will be approved or how long it will take. It does not assess eligibility. It does not give migration advice or recommend a visa. It does not take or repeat identity details. It does not discuss another person's case. It does not discuss enforcement operations. |
| **Model and platform** | Genesys Cloud agentic virtual agent with custom guardrails (version 1). [Confirm the underlying model, where inference runs, and the provider's data-use terms] |
| **Data used** | The approved knowledge base only. The assistant is told not to accept identity or health details. The lab function sees a reference number only. [Confirm retention of conversation transcripts and who can read them] |
| **People affected** | Members of the public calling or chatting, including people with disability, limited English, older people and people in distress |
| **Does it make or substantially make a decision about a person?** | No. It gives general information only. [Privacy officer to confirm for the purposes of APP 1.7 to 1.9, in force from 10 December 2026] |
| **Disclosure to the person** | The greeting and the chat panel say it is an automated assistant [wording to be approved] |
| **Human oversight** | A person is one step away at all times. Three blocked requests cause an automatic hand-off. Safety keywords cause an immediate transfer. Quality evaluation samples handled calls |
| **Main risks** | Wrong or outdated information; the assistant being manipulated; a person in danger not being routed; personal information being shared with the assistant; people who cannot use it |
| **Controls** | Instructions; custom guardrail rules; knowledge-only tool; violation threshold; transfer; redaction; speech and text analytics; kill switch (republish the flow without the assistant); version control and pull-request review; release test list |
| **Test evidence** | Build Manual, Part 6 (allow, block, injection, hand-off, safety). [Attach results and dates] |
| **Review date** | [At least annually, and on any change to the model, rules or content] |
| **Impact assessment** | See `AI-IMPACT-ASSESSMENT-OUTLINE.md`. [Status and date] |
| **Public statement** | See `TRANSPARENCY-STATEMENT-NOTES.md`. [Link when published] |
