<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Antenna synchronization

Complete [the setup guide](../../SETUP-GUIDE.md) through Step 6, then follow [Step 7](../../docs/07-SYNC-AGENT-TO-VAULT.md). It includes environment creation, certificate generation, template rendering, container startup, SSF stream creation, local reconciliation and actual tenant webhook delivery.

The runnable files are in `reference-implementation/`. The transmitter pushes management notifications into a signed SSF stream; the receiver polls it, reads the current agent from Verify and provisions Vault through restricted API credentials.
