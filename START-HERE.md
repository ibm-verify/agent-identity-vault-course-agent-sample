<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Start the Course Agent lab

1. Extract this archive into a new folder. Do not overlay it on an existing configured lab.
2. Open `SETUP-GUIDE.md` and begin with workstation preparation.
3. Create `lab.env` by copying `lab.env.example` in this repository root, alongside README.md.
4. Create the one recipe API client and four runtime applications shown in the guide. No additional SSF application is required.
5. Follow each checkpoint in order before proceeding to the next step.

If a previous dedicated run is active, stop its portal and ngrok with Ctrl-C. Run `docker compose down` from that run's Antenna directory to release its two container names. Stop the dedicated dev Vault only if its state can be discarded; a new dev-server process starts with empty state. Disable the previous dedicated webhook before creating the new one. Do not stop unrelated services or delete shared Verify objects.

All first-time setup commands, inputs and expected outcomes are in SETUP-GUIDE.md. The `app/`, `verify/`, `vault/` and `sync/` directories contain the implementation used by those steps.
