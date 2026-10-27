---
name: game-story-workflow
description: Use when writing or revising game stories, character cards, character motivations, relationships, quests, narrative dialogue, or Chinese story prose; especially when users request 故事、角色卡、人物动机、剧情任务、结构性悲剧 or criticize narrative wording. Not for pure code, performance, builds, or visual asset processing.
---

# Game story workflow

This skill coordinates existing narrative and Chinese writing skills. It does not contain a game's canon or authorize implementation, publishing, installation of dependencies, or Git operations.

## First choose the task size

- **One-line wording fix:** read the supplied sentence and relevant confirmed speaker context. Preserve meaning. Do not demand six character cards or invent a new scene.
- **Character, scene, quest, or story work:** identify confirmed facts, revoked proposals, unknowns, and the requested deliverable before drafting. Use the sequence below at the scale the request needs.
- **Pure technical/art-processing work:** stop this workflow and use the appropriate technical capability. A code identifier containing `story` does not make the task narrative work.

## Read the real dependencies

Use the active skill catalog to locate each SKILL.md. If it was actually read in this conversation and remains available in context, reuse it; saying a name is not reading it. If the catalog is stale, `scripts/resolve_dependencies.py --mode narrative` reports likely installed paths under `.agents/skills` and `.codex/skills`. It only finds paths; it does not read or invoke skills.

1. Narrative work: read **game-narrative** and its `references/local-adaptation.md`.
2. Select references inside that skill by actual need:
   - Motivation, decisions, relationships: `references/agency-agents/psychologist.md`.
   - Plot causality, revelations, tragedy: `references/agency-agents/narratologist.md`.
   - Quests, dialogue, environmental information: `references/agency-agents/narrative-designer.md`.
   - Institutions and social arrangements: `references/agency-agents/anthropologist.md`, only when relevant.
3. Chinese game-design explanation: read **game-design-natural-writing-zh** before writing that explanation.
4. After facts and causal structure are settled, read **clear-natural-writing** for final narrative/dialogue wording. For a wording-only edit, read it immediately and preserve the original language and character voice. Use **game-design-natural-writing-zh** for Chinese design explanations; do not apply its expository tone to every character. Removed humanizer skills are not called.

Read only required references and relevant project sources. Do not read every specialist by default. If long output is truncated, read the missing relevant section before claiming it was inspected. No theoretical citations are necessary unless they materially support an actual claim; do not invent research claims.

If a required skill is unavailable, report its actual name and the search performed. Continue independent work only; do not complete dependent work while pretending the skill ran. Do not encode skills as MCP tool dependencies.

## Build behavior before dialogue

1. **Fact boundary:** list protected facts and IDs, and explicitly remove revoked proposals from the working premise. A revoked premise cannot survive through a renamed object or a dependent mechanism. New ideas are proposals, not established canon.
2. **Characters:** use `references/character-card.md` for a full card; for an existing character reuse the relevant established fields. Before a new consequential dialogue, determine at least the speaker's immediate want, knowledge, leverage, and refusal boundary.
3. **Relationships:** establish what each person wants from the other, can offer/withhold, and currently believes. Do not substitute personality labels or diagnoses for observable behavior.
4. **Causal events:** use `references/event-card.md`. State who acts, why now, what was known then, and what changes. Check the obvious easier alternatives. If everyone can walk away safely, explain why they do not or revise the event.
5. **Quests and reveal order:** translate actions into reachable places and observable state changes. The player must understand the immediate objective without collecting all lore. Keep author knowledge separate from speaker knowledge.
6. **Dialogue:** people ask, refuse, bargain, evade or act on something present. Do not force every exchange to end in a memorable line. Wording cannot repair an undefined motive.
7. **Language pass:** preserve IDs, quantities, logical operators, conditions, placeholders and branch consequences. Rewrite sentences so people perform actions. Remove unnecessary `在…中/上`, `对…的`, abstract passive subjects and slogan-like summaries only when they obscure the actual relation; do not ban prepositions mechanically.

When asked to write dialogue before a decisive motive exists, do not silently invent a benevolent motive and proceed. Give the minimum provisional motive/relationship comparison or ask the one necessary question. If the user explicitly requests a speculative scene, label the assumptions before it, without promoting them into project canon.

## Difficult tone and tragedy

Darkness is not a request for additional wounds or deaths. Identify the competing wants, what each choice preserves, and the damage caused by people following those choices. Label additions as proposals. Do not automatically turn a hunter into a rescuer or assume a hidden villain makes the choice easy.

Check setup before irreversible loss, the causal mechanism of the loss, and what exploration can still change. Do not guarantee every good act is punished. Everyday affection, pleasure and ordinary disagreements can matter without becoming moral lessons. Do not imitate an author's characteristic wording when the user is asking for structural qualities.

## Evidence and review

Deliver usable cards/scenes/quest text, not just advice about making them. For project work append a compact **execution record outside the finished prose**: actual dependency paths read or reused, chosen references, artifact paths, pending decisions, and checks performed. This is an operational record, not hidden reasoning. For a one-line edit, do not burden the answer with a report unless requested.

Before delivery verify:
- New character cards cover all requested fields and concrete behaviors.
- Consequential dialogue is grounded in wants, knowledge and leverage.
- New/revoked/confirmed facts remain distinguishable.
- No unannounced harmful twist was added just to make the scene darker.
- Protected strings and numeric conditions match the original.
- Missing dependencies and unverified outcomes are reported honestly.

Read `references/acceptance-cases.md` when changing or validating this skill. Behavior must be tested in independent sessions; a file/schema check alone does not establish correct routing.
