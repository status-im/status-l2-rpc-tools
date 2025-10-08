#!/bin/bash
set -e

echo "🚀 Status Sepolia Community Node Setup"
echo "======================================"

BESU_GENESIS_URL="https://raw.githubusercontent.com/status-im/status-l2-rpc-tools/refs/heads/master/1660990954/genesis/besu-genesis.json"
GETH_GENESIS_URL="https://raw.githubusercontent.com/status-im/status-l2-rpc-tools/refs/heads/master/1660990954/genesis/geth-genesis.json"

# Check dependencies
if ! command -v docker &> /dev/null; then
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "❌ curl not found. Please install curl first."
    exit 1
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p config/{besu,geth} geth-data besu-data
chmod 755 geth-data besu-data

# Download genesis files
echo "📥 Downloading genesis files..."

echo "  → Downloading Besu genesis.json..."
curl -fsSL "$BESU_GENESIS_URL" -o config/besu/genesis.json

echo "  → Downloading Geth genesis.json..."
curl -fsSL "$GETH_GENESIS_URL" -o config/geth/genesis.json

# Verify downloads
if [ ! -s config/besu/genesis.json ]; then
    echo "❌ Failed to download Besu genesis.json"
    exit 1
fi

if [ ! -s config/geth/genesis.json ]; then
    echo "❌ Failed to download Geth genesis.json"
    exit 1
fi

echo "✅ Genesis files downloaded successfully"

# Create docker-compose.yml
echo "🐋 Creating docker-compose.yml..."
cat > docker-compose.yml << 'COMPOSE_EOF'
services:
  # === BESU SERVICE ===
  besu:
    image: consensys/linea-besu-package:beta-v2.1-rc16.2-20250521134911-f6cb0f2
    platform: linux/amd64
    container_name: besu-l2-node
    restart: unless-stopped
    ports:
      - "8545:8545"     # HTTP RPC
      - "8546:8546"     # WebSocket RPC
      - "30303:30303"   # P2P
      - "30307:30307"   # P2P Discovery
      - "9545:9545"     # Metrics

    environment:
      RPC_BESU_ENODE: enode://f3fa2c440cb6843ca8258abd3c01e2e1be5afa158bae7cfe875167ecbe56718d3f18354d47d5a106f396834adbea9864f07a6fa6c13cab71e954c6145e87f19a@13.49.112.210:30303
      LOG4J_CONFIGURATION_FILE: /var/lib/besu/log4j.xml

    volumes:
      - ./config/besu/config.toml:/var/lib/besu/config.toml:ro
      - ./config/besu/log4j.xml:/var/lib/besu/log4j.xml:ro
      - ./config/besu/genesis.json:/var/lib/besu/genesis.json:ro
      - ./config/besu/static-nodes.json:/opt/besu/local/static-nodes.json:ro
      - ./config/besu/traces-limits.toml:/var/lib/besu/traces-limits.toml:ro
      - ./config/besu/deny-list.txt:/var/lib/besu/deny-list.txt:ro
      - ./besu-data:/data

    entrypoint:
      - /opt/besu/bin/besu
      - --config-file=/var/lib/besu/config.toml
      - --plugin-linea-node-type=RPC
      - --Xdns-enabled=true
      - --Xdns-update-enabled=true
      - --bootnodes=enode://f3fa2c440cb6843ca8258abd3c01e2e1be5afa158bae7cfe875167ecbe56718d3f18354d47d5a106f396834adbea9864f07a6fa6c13cab71e954c6145e87f19a@13.49.112.210:30303
      - --p2p-host=0.0.0.0
      - --p2p-port=30303
      - --data-path=/data/status-sepolia-l2-node-besu

  # === GETH SERVICES ===
  geth-init:
    image: consensys/linea-geth:0588665
    platform: linux/amd64
    restart: "no"
    volumes:
      - ./geth-data:/data
      - ./config/geth/genesis.json:/local/genesis.json:ro
    command: [
      "init",
      "--datadir", "/data/status-sepolia-rpc-geth",
      "/local/genesis.json"
    ]

  geth:
    image: consensys/linea-geth:0588665
    platform: linux/amd64
    container_name: status-sepolia-rpc-geth
    restart: unless-stopped
    depends_on:
      geth-init:
        condition: service_completed_successfully

    ports:
      - "8445:8545"     # HTTP RPC (different port to avoid conflict with Besu)
      - "8447:8546"     # WebSocket RPC (different port to avoid conflict with Besu)
      - "9100:9100"     # Metrics

    environment:
      DISABLE_ZKEVM: "true"
      MAX_BLOCKDATA_BYTES: 120000

    volumes:
      - ./geth-data:/data

    entrypoint: ["geth"]
    command:
      [
        "--datadir", "/data/status-sepolia-rpc-geth",
        "--networkid", "1660990954",
        "--miner.gasprice", "0x0",
        "--miner.gaslimit", "0x1C9C380",
        "--http", "--http.addr", "0.0.0.0", "--http.port", "8545",
        "--http.api", "admin,eth,miner,net,web3,personal,txpool,debug",
        "--http.vhosts=*",
        "--http.corsdomain=*",
        "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8546",
        "--ws.api", "admin,eth,miner,net,web3,personal,txpool,debug",
        "--metrics", "--metrics.addr", "0.0.0.0", "--metrics.port", "9100",
        "--bootnodes", "enode://f3fa2c440cb6843ca8258abd3c01e2e1be5afa158bae7cfe875167ecbe56718d3f18354d47d5a106f396834adbea9864f07a6fa6c13cab71e954c6145e87f19a@13.49.112.210:30303",
        "--verbosity", "4",
        "--syncmode", "full",
        "--gcmode", "archive",
        "--txpool.pricelimit", "0",
        "--mine=false",
        "--ipcdisable",
      ]
COMPOSE_EOF

echo "✅ docker-compose.yml created"


# Create other config files
echo "📝 Creating configuration files..."

# Create config.toml
cat > config/besu/config.toml << 'EOF'
### Data and Storage ###
genesis-file="/var/lib/besu/genesis.json"
logging="DEBUG"
data-path="/data/status-sepolia-l2-node-besu"
data-storage-format="FOREST"
sync-mode="FULL"

### Node and Network configuration ###
host-allowlist=["*"]
discovery-enabled=true
max-peers=50
p2p-port=30303
static-nodes-file="local/static-nodes.json"

### Transaction pool ###
tx-pool-enable-save-restore=true
tx-pool-max-future-by-sender=1000
tx-pool-min-gas-price=0
tx-pool-layer-max-capacity="100000000"
tx-pool-no-local-priority=true

### RPC and API configuration ###
rpc-http-enabled=true
rpc-http-host="0.0.0.0"
rpc-http-port=8545
rpc-http-api=["ETH","NET","WEB3","DEBUG","TRACE","TXPOOL","LINEA","MINER"]
rpc-http-cors-origins=["*"]
rpc-http-max-active-connections=200

rpc-ws-enabled=true
rpc-ws-api=["ETH","NET","WEB3"]
rpc-ws-host="0.0.0.0"
rpc-ws-port=8546
rpc-ws-max-active-connections=200

rpc-gas-cap=50000000
graphql-http-enabled=false

api-gas-price-max=0
api-gas-price-blocks=0
api-gas-price-percentile=0
api-gas-and-priority-fee-limiting-enabled=true
api-gas-and-priority-fee-lower-bound-coefficient=100
api-gas-and-priority-fee-upper-bound-coefficient=100

Xplugin-rocksdb-high-spec-enabled=true

### JWT and Engine Configuration ###
engine-jwt-disabled=true
engine-rpc-enabled=false
engine-rpc-port=8550
engine-host-allowlist=["*"]

### Gas and Block Limit Configuration ###
min-gas-price=0
target-gas-limit="2000000000"

metrics-enabled=true
metrics-host="0.0.0.0"
metrics-port=9545

### Plugin Configuration ###
plugins=["LineaEstimateGasEndpointPlugin","LineaL1FinalizationTagUpdaterPlugin","LineaExtraDataPlugin","LineaTransactionPoolValidatorPlugin"]
plugin-linea-module-limit-file-path="/var/lib/besu/traces-limits.toml"

plugin-linea-estimate-gas-min-margin="0.0"
plugin-linea-min-margin="0.0"
plugin-linea-tx-pool-min-margin="0.0"
plugin-linea-variable-gas-cost-wei=0
plugin-linea-extra-data-pricing-enabled=false
plugin-linea-extra-data-set-min-gas-price-enabled=false
plugin-linea-tx-pool-profitability-check-api-enabled=false
plugin-linea-tx-pool-profitability-check-p2p-enabled=false
plugin-linea-deny-list-path="/var/lib/besu/deny-list.txt"
plugin-linea-l1-rpc-endpoint="https://rpc.eu-central-1.gateway.fm/v4/ethereum/non-archival/sepolia"

plugin-linea-l1-smart-contract-address="0xe74Bd8db0440533F8915042D980AbAA86085821c"
plugin-linea-l1l2-bridge-contract="0xe74Bd8db0440533F8915042D980AbAA86085821c"
plugin-linea-fixed-gas-cost-wei=0

plugin-linea-l1-polling-interval="PT12S"
Xin-process-rpc-enabled=true
Xin-process-rpc-apis=["MINER", "ETH"]
EOF

# Create log4j.xml
cat > config/besu/log4j.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="INFO" monitorInterval="2">
  <Properties>
    <Property name="root.log.level">WARN</Property>
  </Properties>

  <Appenders>
    <Console name="Console" target="SYSTEM_OUT">
      <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSSZZZ} | %t | %-5level | %c{1} | %msg %throwable%n" />
    </Console>
  </Appenders>
  <Loggers>
    <Logger name="org.hyperledger.besu" level="WARN" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="org.hyperledger.besu.ethereum.eth.sync.fullsync.FullSyncTargetManager" level="INFO" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="org.hyperledger.besu.ethereum.blockcreation" level="INFO" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="org.hyperledger.besu.consensus.merge.blockcreation" level="INFO" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="org.hyperledger.besu.ethereum.api.jsonrpc" level="TRACE" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="io.opentelemetry" level="WARN" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="net.consensys.linea.sequencer.txselection.selectors" level="DEBUG">
      <AppenderRef ref="Console"/>
    </Logger>
    <Logger name="org.hyperledger.besu.ethereum.eth.transactions.TransactionPool" level="TRACE" additivity="false">
      <AppenderRef ref="Console"/>
    </Logger>
    <Root level="${sys:root.log.level}">
      <AppenderRef ref="Console"/>
    </Root>
  </Loggers>
</Configuration>
EOF

# Create static-nodes.json
cat > config/besu/static-nodes.json << 'EOF'
["enode://f3fa2c440cb6843ca8258abd3c01e2e1be5afa158bae7cfe875167ecbe56718d3f18354d47d5a106f396834adbea9864f07a6fa6c13cab71e954c6145e87f19a@13.49.112.210:30303"]
EOF

# Create traces-limits.toml
cat > config/besu/traces-limits.toml << 'EOF'
[traces-limits]
#
# Arithmetization module limits
#
ADD                 = 262144
BIN                 = 262144
BLAKE_MODEXP_DATA   = 16384
BLOCK_DATA          = 4096
BLOCK_HASH          = 2048
EC_DATA             = 65536
EUC                 = 65536
EXP                 = 65536
EXT                 = 524288
GAS                 = 65536
HUB                 = 2097152
LOG_DATA            = 65536
LOG_INFO            = 4096
MMIO                = 2097152
MMU                 = 1048576
MOD                 = 131072
MUL                 = 65536
MXP                 = 524288
OOB                 = 262144
RLP_ADDR            = 4096
RLP_TXN             = 131072
RLP_TXN_RCPT        = 65536
ROM                 = 8388608 # Note: set as 6291456 in production as workaround
ROM_LEX             = 1024
SHAKIRA_DATA        = 65536
SHF                 = 262144
STP                 = 16384
TRM                 = 32768
TXN_DATA            = 8192
WCP                 = 262144
#
# Reference table limits, set to Integer.MAX_VALUE
#
BIN_REFERENCE_TABLE = 2147483647
SHF_REFERENCE_TABLE = 2147483647
INSTRUCTION_DECODER = 2147483647
#
# Precompiles limits
#
PRECOMPILE_ECRECOVER_EFFECTIVE_CALLS        = 128
PRECOMPILE_SHA2_BLOCKS                      = 200
PRECOMPILE_RIPEMD_BLOCKS                    = 0
PRECOMPILE_MODEXP_EFFECTIVE_CALLS           = 32
PRECOMPILE_ECADD_EFFECTIVE_CALLS            = 1024
PRECOMPILE_ECMUL_EFFECTIVE_CALLS            = 40
PRECOMPILE_ECPAIRING_FINAL_EXPONENTIATIONS  = 16
PRECOMPILE_ECPAIRING_G2_MEMBERSHIP_CALLS    = 64
PRECOMPILE_ECPAIRING_MILLER_LOOPS           = 64
PRECOMPILE_BLAKE_EFFECTIVE_CALLS            = 0
PRECOMPILE_BLAKE_ROUNDS                     = 0
#
# Block-specific limits
#
BLOCK_KECCAK        = 8192
BLOCK_L1_SIZE       = 1000000
BLOCK_L2_L1_LOGS    = 16
BLOCK_TRANSACTIONS  = 300
EOF

# Create empty deny-list.txt
touch config/besu/deny-list.txt

echo "✅ Configuration files created"

# Pull Docker images
#echo "📦 Pulling Docker images (this may take a while)..."
#docker pull consensys/linea-geth:0588665
#docker pull consensys/linea-besu-package:beta-v2.1-rc16.2-20250521134911-f6cb0f2

# Initialize Geth
echo "🔧 Your node is ready to be started!"

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎯 Start Options:"
echo "   docker compose up -d         # 🚀 Run both nodes"
echo "   docker compose up geth -d    # 🟢 Run only Geth node"
echo "   docker compose up besu -d    # 🔵 Run only Besu node"
echo ""
echo "🌐 Endpoints will be available at:"
echo "   - Geth HTTP RPC: http://localhost:8645"
echo "   - Geth WebSocket: ws://localhost:8646"
echo "   - Besu HTTP RPC: http://localhost:8545"
echo ""
echo "📊 To monitor:"
echo "   docker compose logs -f"