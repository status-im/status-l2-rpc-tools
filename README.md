# Status Network - RPC Tools

<img align="right" alt="sn-team"  height="150" src=".github/assets/pampi.png">

Tooling to get you started in running your own RPC for [Status Network](https://status.network). 
This repo contains genesis files as well as the setup script to get started.

Good luck! 🍀
<br/>
<br/>
<br/>

## Overview

This repository provides comprehensive tooling to help you set up and run your own Remote Procedure Call (RPC) node for the Status Network. By running your own RPC node, you can gain greater control over your interactions with the Status Network, enhance privacy, and reduce reliance on third-party services.

## Prerequisites

Before you begin, ensure you have the following:

- [**Git**](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git): To clone repositories. 
- **Bash Shell**: To execute shell scripts. This is typically available on Unix-based systems (Linux, macOS)
- **Basic Command Line Knowledge**: Familiarity with terminal commands

### System Requirements

| Node Type      | Storage    | vCPU     | RAM        | Disk (Gen4 NVMe) | Network Connection    |
|:-------------- |:---------- |:-------- |:---------- |:---------------- |:---------------------|
| **Full Node**  | ~200 GB    | 8–12     | 32–48 GB   | 2 TB             | 1 Gbps               |

> 📝 **Note:** Archive node support is an upcoming feature and will be available in a future release.

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/status-im/status-l2-rpc-tools.git
```

### 2. Identify the Chain ID

Find the Chain ID of the Status Network you wish to run the RPC node for in the table below or on [Chainlist](https://chainlist.org/).

| Name                   | Chain ID   |
| ---------------------- | ---------- |
| Status Network Sepolia | 1660990954 |

### 3. Create a Directory for Your RPC Node 

```bash
mkdir status-l2-rpc
```

⚠️ The directory should be outside of the `status-l2-rpc-tools` repository folder. 

### 4. Copy the Setup Script

```bash
cp ./status-l2-rpc-tools/<CHAIN_ID>/setup.sh ./status-l2-rpc/setup.sh
```

**Important**: Replace <CHAIN_ID> with the one you picked in step 2 (e.g., `1660990954` for Status Network Sepolia).

### 5. Execute the Setup Script

```bash
chmod +x ./setup.sh
./setup.sh
```

Then follow the instructions provided by the script output. 

### 6. Start the node

If completed successfully, you will have three start options:

```bash
docker compose up -d         # 🚀 Run both nodes
docker compose up geth -d    # 🟢 Run only Geth node
docker compose up besu -d    # 🔵 Run only Besu node
```

### 7. Verify Your RPC Node

Once Docker is running, check your node is up by running:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:<PORT>
```

- Use `8545` for Besu (http://localhost:8545)
- Use `8445` for Geth (http://localhost:8445)

You should receive a response with a block number if your node is running properly.


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
