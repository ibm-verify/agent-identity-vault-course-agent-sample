# Agent Synchronization Options

The main runtime requires the Course Assistant actor to be registered in Vault before the premium tool is invoked.

Choose one path:

- `antenna/` — reference IBM Verify Antenna/SSF recipe, including ngrok and lifecycle tests.
- `custom-adapter/` — vendor-neutral synchronization contract for teams that prefer their own service or integration platform.

Both paths must produce the same Vault state:

```text
Vault Identity entity
+ OAuth alias for the actor runtime identity
+ Agent Registry registration
+ course-tool-ceiling
```

The synchronization integration uses a restricted Vault provisioning token. The Course Assistant runtime never receives that token.
