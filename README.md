[![RepoLens — ask your codebase, get answers with line numbers](docs/assets/repolens-banner.svg)](docs/assets/repolens-banner.svg)

**Code intelligence for any codebase.** Import a repository — Java, Python, TypeScript, Go, Rust, C#, Ruby, PHP and 20+ more languages, in any mix — and RepoLens answers questions about it with file-and-line citations, reviews it like a senior engineer, and maps its riskiest files using both the code and its git history.

![Java 21](https://img.shields.io/badge/Java-21-E76F00?style=flat&logo=openjdk&logoColor=white)
![Spring Boot 3.5](https://img.shields.io/badge/Spring%20Boot-3.5-6DB33F?style=flat&logo=springboot&logoColor=white)
![React 19](https://img.shields.io/badge/React%2019-TypeScript-3178C6?style=flat&logo=react&logoColor=white)
![PostgreSQL + pgvector](https://img.shields.io/badge/PostgreSQL-pgvector-4169E1?style=flat&logo=postgresql&logoColor=white)
![Ollama](https://img.shields.io/badge/LLM-local%20Ollama-18181B?style=flat)
![30+ languages](https://img.shields.io/badge/languages-30%2B-EA580C?style=flat)

[Get started](#get-started) · [What it does](#what-it-does) · [How it works](#how-it-works) · [Configuration](#configuration) · [Development](#development) · [Project map](#project-map)

---

![RepoLens chat — one answer that walks a login flow from a React form to a FastAPI endpoint, citing both](docs/assets/screenshots/chat.png)

## The idea

```
 GitHub / ZIP ──► files (30+ languages) ──► structure-aware chunks ──► embeddings (local) ──► pgvector
      │                                    (one per function / class)                          │
      └─► git history (last 300 commits) ──► churn + bug-fix counts ──► risk map               │
                                                                                               │
 your question ──► hybrid retrieval (vector + keyword, RRF) ◄──────────────────────────────────┘
                   + spread across files + one hop to referenced files + project file map
                          │
                          ▼
                  prompt with cited chunks ──► local Ollama (qwen2.5-coder:7b) ──► streamed answer
                                                                                   + [File.java:42-60]
```

Every claim about your code links to the exact lines. If the context doesn't contain the answer, RepoLens says so instead of guessing.

## What it does

**Chat with your codebase.** Streamed answers grounded in the indexed code, with clickable `[auth_service.py:42-60]` citations that open the file at that line. Questions that span many files ("walk me through the login flow from the form to the database", "list all API routes") pull in code from across the project: results are spread over files, the files the retrieved code references are followed one hop, and the model sees a map of every file so it can say where the rest lives instead of guessing. Multiple conversations per project with search, rename, delete, copy and regenerate.

**Every language.** Java, Kotlin, Scala, Groovy, C#, C, C++, Objective-C, Go, Rust, Swift, Dart, JavaScript, TypeScript, Vue, Svelte, PHP, Python, Ruby, Elixir, R, Lua, Shell, PowerShell and SQL, plus HTML/CSS, Markdown docs and config (YAML, TOML, JSON, Dockerfile, Terraform, Protobuf, GraphQL, Makefile). Java is chunked with a real parser; every other language is cut along its functions and classes, never mid-function. Tests, generated code (`*.gen.ts`, `*_pb2.py` …), lock files and dependency folders are skipped.

**AI code review.** Pick up to five files in any language and an optional focus ("security", "transactions"). Issues come back sorted by severity, each tied to a real file and line, with a suggested fix. Invented files and lines are filtered out before you see them.

**Risk map.** Static analysis of every source file in every language — cyclomatic complexity, size, nesting depth, parameter counts and smells such as swallowed errors, catch-all handlers, debug output, `eval()` and TODOs. GitHub imports bring the last 300 commits of history, so files that change often and keep needing bug fixes rank higher (a ZIP that includes its `.git` folder works too). Deterministic and free: no AI involved.

**GitHub and Google, one click.** *Continue with GitHub* signs you in and connects your account in one step; pick any repository you can access (private ones included) and import it. *Continue with Google* works too, and ZIP upload is always there.

**Your profile.** A username and a picture: the picture comes from GitHub or Google automatically when you sign in with them, and you can upload your own (cropped in the browser), switch back, or remove it.

**Fully local AI.** Chat, code review and embeddings all run on your machine through Ollama — no API keys, and your code never leaves it.

<table>
  <tr>
    <td><img src="docs/assets/screenshots/review.png" alt="AI code review with severity-sorted issues and suggested fixes"></td>
    <td><img src="docs/assets/screenshots/risk.png" alt="Risk map with complexity, size and warnings per file"></td>
  </tr>
  <tr>
    <td><img src="docs/assets/screenshots/sign-in.png" alt="Sign in with GitHub, Google or email"></td>
    <td><img src="docs/assets/screenshots/code-dark.png" alt="Code explorer in dark mode"></td>
  </tr>
  <tr>
    <td><img src="docs/assets/screenshots/profile.png" alt="Profile with username and picture"></td>
    <td></td>
  </tr>
</table>

## Get started

### You'll need

- **Docker** (for PostgreSQL + pgvector)
- **Java 21** — `brew install openjdk@21` on macOS
- **Node.js 20.19+**
- **Ollama** — `brew install ollama` (runs chat, review and embeddings)

### Install

```bash
# 1. database
docker compose up -d

# 2. local models
ollama serve &                      # or: brew services start ollama
ollama pull nomic-embed-text        # embeddings (required)
ollama pull qwen2.5-coder:7b        # chat + review model

# 3. backend secrets (gitignored) — creates Backend/backend/.env with fresh JWT_SECRET + GITHUB_TOKEN_KEY
bash scripts/setup-env.sh
# Windows PowerShell: powershell -ExecutionPolicy Bypass -File scripts\setup-env.ps1

# 4. backend → http://localhost:8080  (Swagger: /swagger-ui.html when DEV_TOOLS_ENABLED=true)
cd Backend/backend && ./mvnw spring-boot:run

# 5. frontend → http://localhost:5173
cd frontend && npm install && npm run dev
```

Create an account (or use **Continue with GitHub**), import a repository, press **Index project**, and start asking.

### GitHub sign-in (optional)

Create an OAuth App at [github.com/settings/developers](https://github.com/settings/developers):

| Field | Value |
| --- | --- |
| Homepage URL | `http://localhost:5173` |
| Authorization callback URL | `http://localhost:5173/integrations/github/callback` |

Put its client ID and secret in `Backend/backend/.env` as `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` and restart the backend. The *Continue with GitHub* button appears automatically once they are set.

### Google sign-in (optional)

Create an OAuth client ID (type *Web application*) at [console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials:

| Field | Value |
| --- | --- |
| Authorized JavaScript origins | `http://localhost:5173` |
| Authorized redirect URI | `http://localhost:8080/login/oauth2/code/google` |

Put its client ID and secret in `Backend/backend/.env` as `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` and restart the backend. While the consent screen is in *Testing* mode, only accounts listed under **Test users** can sign in.

## How it works

- **Languages** — one registry (`language/Language.java`) decides, per language, which files belong to it and how its comments and strings look. The same registry drives import, indexing, chunking, review and the risk map, and the frontend's syntax highlighting mirrors it.
- **Indexing** — source, config and docs are kept; tests, generated and minified files are skipped. Java is cut by a JavaParser AST chunker (one chunk per class outline and per method); every other language by a structure chunker that finds functions, classes and Markdown sections by pattern, merges tiny pieces and splits long ones with overlap. Chunks are embedded with `nomic-embed-text` (768 dimensions) into pgvector as a background job with live progress.
- **Retrieval** — vector similarity and PostgreSQL full-text search (camelCase-aware) run in parallel and are merged with Reciprocal Rank Fusion, then spread across files (max 3 chunks per file; broad questions get a wider net). The outlines of project files the retrieved code references are added (one hop: controller → service → repository), and the prompt carries a compact map of every indexed path. Short follow-ups borrow the previous question.
- **History** — GitHub imports clone the last 300 commits instead of one; a ZIP that contains `.git` is read too. Per file: commits, bug-fix commits (by message), authors and last change, stored at import time and folded into the risk score.
- **Answering** — the prompt carries the cited chunks (with prompt-injection guard rules) and the recent conversation. Answers stream over SSE as `token → sources → done`; errors arrive as an `error` event, never a hung stream.
- **AI router** — `LlmRouter` is the single entry point to the local Ollama chat model. Each saved answer records which model wrote it.
- **Security** — stateless JWT; every project, file and conversation query is scoped to its owner. API keys and GitHub tokens live only on the server (tokens AES-GCM encrypted at rest); OAuth state is HMAC-signed, purpose-bound and expires after 10 minutes.

## Configuration

Everything except `JWT_SECRET` and `GITHUB_TOKEN_KEY` has a working local default; secrets go in `Backend/backend/.env` (see [`.env.example`](Backend/backend/.env.example)).

| Variable | Default | Purpose |
| --- | --- | --- |
| `OLLAMA_CHAT_MODEL` | `qwen2.5-coder:7b` | Chat and code-review model |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama server |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | — | GitHub sign-in and private repo import |
| `GITHUB_TOKEN_KEY` | **required** | 32-byte base64 key encrypting stored GitHub tokens (`openssl rand -base64 32`) |
| `JWT_SECRET` | **required** | Signs login tokens, ≥32 chars (`openssl rand -base64 48`) |
| `DEV_TOOLS_ENABLED` | `false` | Swagger UI + `/api/ai/test-*` debug endpoints — local development only |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | local Docker | PostgreSQL connection |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | — | *Continue with Google* (redirect: `http://localhost:8080/login/oauth2/code/google`) |

Commits of history read per GitHub import: `app.github.history-depth` (default 300) in `application.yml`.

## Development

```bash
# frontend (from frontend/)
npm run check          # typecheck + lint + format check + tests
npm run dev:mock       # whole UI with a fake API in the browser — chat streams, review and risk work too
npm run format         # Prettier (with Tailwind class sorting)

# backend (from Backend/backend/)
./mvnw test                                   # all tests (the context test needs Postgres)
./mvnw test -Dtest=LlmRouterTest              # one class
./mvnw spotless:apply                         # format Java (palantir-java-format); `verify` fails if unformatted
```

Database changes are Flyway migrations in `Backend/backend/src/main/resources/db/migration` (`ddl-auto: validate`).

## Project map

```
Backend/backend/src/main/java/com/repolens/
├── ai/          LlmRouter, OllamaClient, AI status
├── auth/        JWT auth, "Continue with GitHub" sign-in
├── chat/        RAG chat (SSE), conversations, prompt builder
├── chunking/    JavaParser AST chunker + structure chunker for every other language, indexable-file rules
├── file/        repository files on disk + tree/content API
├── github/      import (with history), OAuth connect, repo listing, token encryption
├── history/     git history per file: churn, bug-fix commits, authors
├── indexing/    background index jobs → pgvector
├── language/    language registry, comment/string stripping, function & class detection
├── retrieval/   vector + keyword search, RRF fusion, file spreading, one-hop expansion
├── review/      AI code review (JSON, validated)
├── risk/        risk scores for every language (+ git history)
└── user/        profile: username, pictures (GitHub / Google / upload)
frontend/src/
├── api/         typed API clients (axios + streaming fetch for chat)
├── components/  UI kit, layout, chat, projects, indexing
├── motion/      GSAP route entrances and count-ups
├── pages/       overview, projects, settings, project workspace (code · chat · review · risk)
└── test/        Vitest + Testing Library + MSW
```

---

Built for reading code you didn't write — with the receipts.
