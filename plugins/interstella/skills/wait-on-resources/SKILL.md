---
name: wait-on-resources
description: "MUST be invoked before writing ANY bash command that checks if a service is ready, polls a URL/port, or waits before running the next command. Triggers when about to write: sleep followed by another command, curl to check server status, retry/polling loops, health-check commands, or any 'background process then verify' pattern. Also use when user says 'start server then...', 'wait for it to be ready', 'check if it's running', 'warm up the server'."
---

# Rule

**Use `npx -y wait-on` for ALL resource readiness checks. Never use `sleep`, `curl` polling, or retry loops.**

## Quick Reference

| Wait for... | Command |
|---|---|
| HTTP (HEAD) | `npx -y wait-on http://localhost:3000 -t 30s` |
| HTTP (GET) | `npx -y wait-on http-get://localhost:3000/health -t 30s` |
| TCP port | `npx -y wait-on tcp:localhost:5432 -t 10s` |
| File | `npx -y wait-on file:./dist/index.js -t 2m` |
| Multiple | `npx -y wait-on http://localhost:3000 tcp:localhost:5432 -t 30s` |
| Shutdown | `npx -y wait-on -r tcp:localhost:3000 -t 10s` |

Common flags: `-t` timeout (supports `ms/s/m/h`), `-i` poll interval, `-d` initial delay, `-l` log.

## Choosing Timeout

Don't default to 60s. Estimate how long the resource normally takes, then 2-3x that:
- Fast TCP port check → `-t 10s`
- Vite/lightweight server → `-t 15s`
- Next.js cold start → `-t 45s`
- Large build → `-t 2m`

## Typical Pattern

```bash
bun run dev &
npx -y wait-on http://localhost:3333 -t 30s && bun test
```

## Red Flags — STOP If You Catch Yourself Writing

- `sleep N && curl ...` or `sleep N && NEXT_CMD`
- `curl -s -o /dev/null -w "%{http_code}" ...`
- Any `while ! curl ...; do sleep ...; done` loop
- `curl ... > /dev/null && echo "warm"`
- Increasing sleep values after a failed attempt

Every one of these is a `wait-on` one-liner instead.
