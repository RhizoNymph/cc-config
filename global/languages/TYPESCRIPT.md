When using typescript:
- Use pnpm.
- Always enable strict: true in tsconfig.json. 
- Use vitest for testing.
- Use typed error results or customer error classes. Avoid swallowing errors silently.
- Use pino for logging.
- Use hono for APIs.
- Use Node.js unless a project specifically targets Deno or Bun.
- Use biome for linting and formatting. Fallback to eslint + prettier if biome doesn't cover a needed plugin.
- Use zod for runtime schema validation and type inference.
