# Project Report Blueprint (reverse-engineered from the sample)

Source: `Final_Report__Group-6_.docx` — "MediRoute" (CSE327 Software Engineering, Group 06), ~45 pages, 7 chapters.

This is the **structural skeleton** — what content type goes on each page/section — not the MediRoute content itself. Use this to judge whether Gemini's output matches the expected shape, and to fill in the blanks yourself if it misses something project-specific.

---

## Front Matter (p.1–2)
- Cover page: logo, report title, project name + one-line tagline, course code/name, section/group, submission date, author names + student IDs, instructor name
- Table of Contents with page numbers (chapters + all sub-sections)

## Chapter 1 — Project Description (p.3–10)
- **Intro paragraph**: what the system is, why it exists, roadmap of the chapter's sub-sections
- **1.1 Problem Statement**: 2–4 named sub-problems (each a `#####` sub-heading with 1 paragraph), then a summary paragraph tying them together and pointing at the proposed fix
- **1.2 Solution**: what the system is, how it's structured (list of roles/modules, each with a one-paragraph description of what that role/module does), then a paragraph naming the actual tech stack/architecture layers
- **1.3 Vision Statement**: one italicized quote-style vision statement, followed by 3 bullet "operational commitments," closing with a one-line mission summary
- **1.4 Functional Requirements**: a table of FR-IDs grouped by actor/role (one row per requirement, "shall" phrasing), split across as many pages as needed
- **1.5 Non-Functional Requirements**: a table of NFR-IDs grouped by category (Performance, Security, Reliability, Usability, Maintainability, Scalability, Auditability, Compatibility, etc.)
- **1.6 User Stories**: table of (Role | "As a ___, I want ___ so that ___" | Business Value), covering every role, roughly 1 story per major feature

## Chapter 2 — Related / Sample Work (p.11–14)
- Intro paragraph naming which competitors are surveyed and why
- **2.1 Overview**: paragraph(s) segmenting the competitive landscape into tiers, positioning your project within it
- **2.2–2.4 One sub-section per competitor** (3 total): 2 paragraphs each — what it is/does, then its strengths vs. weaknesses, ending with the specific gap your project fills
- **2.5 Comparison Table**: a full feature-by-feature table (✓ / ✗ / Partial / N/A) across ~20+ features, your project vs. each competitor, split across pages as needed
- **"How to Read the Comparison"**: 2–3 paragraphs interpreting the patterns in the table (your differentiator, your deliberate scope trade-offs, where you match the simplest competitor)

## Chapter 3 — System Diagrams (p.15–20)
- Intro paragraph: which 3 diagrams, what each one shows (external/internal/dynamic view)
- **3.1 Use Case Diagram**: embedded diagram image + one sub-section per actor describing their use cases and any include/extend relationships
- **3.2 Class Diagram**: embedded diagram image, then grouped entity descriptions (e.g. "Core Entities" vs "Workflow Entities"), each entity's attributes + operations in prose, then a "Key Relationships" paragraph listing cardinalities
- **3.3 Sequence Diagram**: embedded diagram image, then one sub-section per end-to-end scenario narrating the message flow between actors/frontend/backend/external services/DB

## Chapter 4 — System Methodology (p.21–26)
- Intro paragraph mapping the 3 sub-sections
- **4.1 System Architecture Overview**: embedded architecture diagram, then one sub-section per layer (Users → Frontend → Backend/middleware/routes/services → Data layer → any external/AI layer), each explained in prose
- **4.2 System Workflow**: a numbered stage-by-stage walkthrough (Stage 1, 2, 3…) of the full end-to-end user journey, tied to specific API calls/DB writes, ending with a paragraph on any cross-cutting role (e.g. admin) that runs parallel to the main flow
- **4.3 Feature-wise Workflow Diagram**: embedded swimlane diagram, a "Reading the Diagram" paragraph walking each lane left-to-right, and a "What the Diagram Highlights" paragraph naming 2–3 architectural decisions the diagram makes visible

## Chapter 5 — Unit Testing (p.27–34)
- Intro paragraph: two-track strategy (black-box + white-box), both run in parallel, failures fixed before feedback round
- **5.1 Black-Box Testing**: intro paragraph on method, then one **Test Suite per major module** (lettered A, B, C…), each a table of (ID | Test Case | Input/Action | Expected Output | Actual Result), plus a closing "Summary" paragraph naming which cases initially failed and how they were fixed
- **5.2 White-Box Testing**: intro paragraph on coverage criteria used (statement/branch/path), a coverage-goals paragraph with final % per service, then one **Test Suite per service/module** (tables same shape as above but "Code Path Tested" + "Coverage Technique" columns), closing "Summary" paragraph naming regressions caught

## Chapter 6 — User Feedback and Performance (p.35–42)
- Intro paragraph: what study was run, sample size, instrument (survey structure)
- **6.1 Executive Summary**: a 3–4 stat "scorecard" row, then 3–4 bullet key takeaways
- **6.2 Research Methodology**: how participants were recruited, what the survey measured
- **6.3 Demographic Snapshot**: breakdown of participant roles/experience
- **6.4 SUS Item-Level Results**: table or list of every survey item with mean score, grouped into Strengths / Neutral / Watch-list, each with 1–2 interpretive sentences
- **6.5 Trust/Reliability Items**: table of statements with mean + % agreement, plus an interpretation paragraph
- **6.6 Qualitative Themes**: a summary table of themes, then one sub-section per theme with 1–2 verbatim quotes (attributed to anonymized participant numbers) and a synthesis paragraph
- **6.7 Key Findings at a Glance**: table of Finding ID | Headline | Evidence
- **6.8 Recommendations for Next Iteration**: table of Priority | Action | Why | Effort | Impact
- **Performance Conclusion**: one closing paragraph tying the numbers back to the benchmark

## Chapter 7 — Conclusion (p.43–45)
- Opening paragraph restating the original problem and the one-line fix
- **7.1 What Was Built**: a factual paragraph inventorying every layer/component actually delivered, then a paragraph mapping delivered work back to the FR/NFR sections
- **7.2 What the Numbers Say**: paragraph pulling the headline stats from Ch.5 and Ch.6 together
- **7.3 What We Learned**: 3 numbered "lessons," each a short paragraph
- **7.4 Challenges Navigated**: paragraph naming each major risk and its mitigation
- **7.5 Future Work**: paragraph listing 5–6 forward-looking directions
- **7.6 Closing Note**: 2–3 sentence closing statement restating the mission and where the project stands

---

# Prompt to give Antigravity (for Gemini)

Copy everything in the code block below into Antigravity. Fill in the bracketed placeholders before sending — Gemini should pull the rest of the actual content from your project's files/codebase, not invent it.

```
You are writing a formal academic Final Project Report in Markdown (.md) for the project "[PROJECT NAME]" — [ONE-LINE DESCRIPTION OF WHAT IT DOES].

Context: read every file in this workspace/repo first (source code, README, requirements docs, ER diagrams, test files, any survey/feedback data, etc.) before writing anything. Do not invent features, test results, or statistics that aren't grounded in the actual project files — if a section's source data genuinely doesn't exist in this project (e.g. no user-feedback study was run), say so explicitly in that section instead of fabricating numbers.

Follow this EXACT structure, chapter and sub-section for chapter and sub-section. Match the tone: formal, third-person, academic software-engineering report style. Use Markdown headings (#, ##, #####), tables, and bullet lists exactly as indicated.

FRONT MATTER
- Title block: project name, tagline, course code [COURSE CODE/NAME], section/group [SECTION/GROUP], submission date, author names + IDs [NAMES/IDS], instructor [INSTRUCTOR NAME]
- Table of contents

CHAPTER 1: PROJECT DESCRIPTION
1.1 Problem Statement — identify 2-4 concrete named problems this project solves, each as its own sub-heading with a paragraph, then a summary paragraph
1.2 Solution — describe the system, its roles/modules, and the actual tech stack found in the codebase
1.3 Vision Statement — one italicized vision statement + 3 bullet operational commitments
1.4 Functional Requirements — a table of FR-IDs (grouped by role/actor) derived from what the code actually implements
1.5 Non-Functional Requirements — a table of NFR-IDs grouped by category (performance, security, reliability, usability, maintainability, scalability, etc.), grounded in what's actually implemented (e.g. only claim a security NFR if auth/hashing is actually in the code)
1.6 User Stories — table of Role | "As a ___, I want ___ so that ___" | Business Value, covering every role/major feature

CHAPTER 2: RELATED / SAMPLE WORK
2.1 Overview of existing alternatives in this problem space
2.2-2.4 One sub-section per competing/comparable product (research real ones if possible), each: what it does, strengths, weaknesses, and the specific gap our project fills
2.5 Comparison Table — feature-by-feature (✓/✗/Partial/N/A), our project vs. each competitor
Closing "How to Read the Comparison" interpretation paragraphs

CHAPTER 3: SYSTEM DIAGRAMS
3.1 Use Case Diagram — describe/generate a Mermaid or PlantUML diagram of actors and use cases, then one sub-section per actor
3.2 Class Diagram — diagram of the actual data model/entities in this codebase, then grouped entity descriptions (attributes + operations) and a relationships paragraph
3.3 Sequence Diagram — diagram + narrated walkthroughs of the 3-5 core end-to-end scenarios in this system

CHAPTER 4: SYSTEM METHODOLOGY
4.1 System Architecture Overview — diagram + one sub-section per actual architectural layer (frontend, backend, database, any external services/APIs)
4.2 System Workflow — numbered Stage 1, 2, 3... walkthrough of the real end-to-end flow, tied to actual routes/functions in the code
4.3 Feature-wise Workflow Diagram — swimlane-style diagram by role, plus "Reading the Diagram" and "What the Diagram Highlights" paragraphs

CHAPTER 5: UNIT TESTING
5.1 Black-Box Testing — one Test Suite table per major module (ID | Test Case | Input/Action | Expected Output | Actual Result), pulled from actual test files if they exist; otherwise write realistic test cases against the FRs in 1.4 and mark them for actual execution
5.2 White-Box Testing — coverage goals + table per service (ID | Function/Module | Code Path | Coverage Technique | Result), citing real coverage % if a coverage report exists in the repo
Both sections end with a Summary paragraph on issues found/fixed

CHAPTER 6: USER FEEDBACK AND PERFORMANCE
[IF NO USER STUDY WAS CONDUCTED: state plainly that no formal feedback round has been run yet, and instead outline the study design that WOULD be used, as a "Planned Evaluation Methodology" sub-section]
[IF A STUDY EXISTS: 6.1 Executive Summary (stat scorecard + key takeaways), 6.2 Methodology, 6.3 Demographics, 6.4 SUS results, 6.5 Trust/Reliability items, 6.6 Qualitative themes with quotes, 6.7 Key Findings table, 6.8 Recommendations table]

CHAPTER 7: CONCLUSION
7.1 What Was Built — factual inventory of every delivered component, mapped back to Ch.1's requirements
7.2 What the Numbers Say — pull real stats from Ch.5/Ch.6
7.3 What We Learned — 3 numbered lessons
7.4 Challenges Navigated — real risks + real mitigations from the project
7.5 Future Work — 5-6 forward-looking directions
7.6 Closing Note — short closing statement

Target length: approximately 45 pages (match the density/detail level of a formal CSE software engineering report, not a short summary). Output as a single .md file, ready to convert to Word/PDF. Use real project artifacts wherever they exist (README content, actual API routes, actual DB schema, actual test files) rather than generic placeholder text.
```

---

### Before you send this
Fill in: project name, one-line description, course code/section/group, author names + IDs, instructor name. Everything else Gemini should extract from your actual project files in the workspace.
