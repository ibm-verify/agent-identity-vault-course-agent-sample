<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 3. Prepare the workstation and workspace

**Purpose:** install the tools, unpack the sample and create the local settings file. No Verify applications, Vault policies, identities, secrets or Antenna streams are assumed to exist.

## 3.1 Obtain the required products and accounts

| Requirement | How to prepare | Check before proceeding |
|---|---|---|
| IBM Verify tenant with IBM Agent Identity enabled | Obtain a tenant and administrator access from your IBM service administrator; sign in to its administration console | AI agents, application management and API access administration are available |
| Human test account | Create it in Step 6 | You can complete interactive authentication |
| Licensed Vault Enterprise build | Obtain the binary for your OS/CPU and an evaluation or purchased license with OAuth Resource Server and Agent Registry capabilities through your IBM/HashiCorp representative | Step 4 starts it and Step 5 activates the required feature |
| Antenna container images | Obtain pull access to `icr.io/ibm-verify/ibm-verify-antenna-transmitter:26.03.0` and `icr.io/ibm-verify/ibm-verify-antenna-receiver:26.03.0` | Step 7 can pull both images |
| ngrok account | Create an account at https://ngrok.com and obtain its authentication token | A public HTTPS tunnel can be started |

Product entitlement, a license file and tenant credentials are external inputs. The sample does not create a tenant or issue a product license. These checks must pass before the remaining setup can succeed.

## 3.2 Install workstation tools

The protocol and application flow are independent of OS. The commands below use Bash. On Windows run them in WSL2 with Docker integration. On Linux use your distribution packages and the vendors' installers. Install Node.js with npm, Python 3, curl, jq, OpenSSL, gettext (`envsubst`), Docker Engine/Desktop with Compose, ngrok and the licensed Vault binary.

On macOS, install Homebrew from https://brew.sh if it is not installed, and follow the installer’s displayed PATH instructions. Then:

```bash
brew install node python jq openssl@3 gettext ngrok
export PATH="$(brew --prefix openssl@3)/bin:$(brew --prefix gettext)/bin:$PATH"
```

Install Docker Desktop from https://www.docker.com/products/docker-desktop/, open it and wait for the engine to become ready. Docker Desktop supplies Compose. A configured Colima engine can also be used; select one engine for the entire lab.

Download the licensed Vault binary matching your CPU, extract it to a private directory such as `~/uc3-tools/vault`, make it executable and add that directory to PATH. Put your license in a separate private file. Record its absolute path; do not copy it into the sample repository.

```bash
bash --version
node --version
npm --version
python3 --version
curl --version
jq --version
openssl version
envsubst --version
docker info
docker compose version
ngrok version
vault version
```

**Expected:** every command runs; `docker info` shows a reachable server. Use Node.js 22 or a later supported LTS release. `vault version` must identify your Enterprise binary. A command-not-found error or unavailable Docker server must be resolved now.

## 3.3 Extract and enter the sample

Download the ZIP and extract it with your file manager. Open Terminal B and enter the extracted folder containing `README.md`, `app/`, `verify/`, `vault/` and `sync/`. For a ZIP downloaded to Downloads:

```bash
bash
cd "$HOME/Downloads"
unzip UC3_Repository_Updated_Verify_Vault_Sync.zip
cd agent-identity-vault-course-agent-sample-main
export UC3_ROOT="$PWD"
umask 077
mkdir -p .runtime
chmod 700 .runtime
cp lab.env.example lab.env
chmod 600 lab.env
```

If the downloaded filename differs, substitute that filename in `unzip`. Keep Terminal B open throughout the setup. `UC3_ROOT` always means this extracted repository root.

**Expected:** `test -f "$UC3_ROOT/app/package.json" && echo PASS` prints `PASS`.

## 3.4 Fill the initial local settings

Open `lab.env` in a text editor. Replace `REPLACE_TENANT_HOST` with the tenant hostname only, without `https://` or a trailing slash. Leave application/agent placeholders until Step 6. Generate a session secret:

```bash
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
```

Copy that output into `SESSION_SECRET`. The API-key value in this sample is a dummy demonstration credential. Keep `PREMIUM_API_EXPECTED_KEY` unchanged for the first run so all steps use the same value. Set the licensed Vault path separately in Terminal A in Step 4. Do not source `app/.env`; it is an application configuration file, not a shell script.

```bash
source "$UC3_ROOT/lab.env"
printf 'Tenant=%s\nVault=%s\nSecret path=%s\n' "$VERIFY_TENANT_HOST" "$VAULT_ADDR" "$VAULT_SECRET_API_PATH"
```

**Expected:** actual tenant hostname, `http://127.0.0.1:8200` and `course-tools/data/premium-enrollment`. No client secret is displayed.

## Terminal plan

| Terminal | Purpose | Keep running |
|---|---|---|
| A | Vault dev server | Throughout all tests |
| B | Setup, curl, Docker and validation | Throughout setup |
| C | ngrok HTTPS tunnel | Throughout synchronization tests |
| D | Course Portal | During the browser demonstration |

All setup commands run in Terminal B unless another terminal is specified. Proceed to **Step 4** only after the workstation checks pass.
