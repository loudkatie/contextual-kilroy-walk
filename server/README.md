# Contextual AI Demo Server

Tiny demo server that calls the ChatGPT API and returns a strict Moment schema.

## Run

```bash
cd server
OPENAI_API_KEY=sk-... node index.js
```

Optional env vars:
- `OPENAI_MODEL` (default: `gpt-4o-mini`)
- `PORT` (default: 8787)

Health check:
```
GET http://localhost:8787/health
```

## iOS hookup
Set the AI server URL in the Demo Controls sheet:
```
http://<your-ip>:8787
```

## Storage
A lightweight JSON file (`data.json`) stores per-user message history.
