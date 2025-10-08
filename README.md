# Status Network - RPC Tools

<img align="left" alt="sn-team"  height="150" src=".github/assets/pampi.png">

Tooling to get you started in running your own RPC for [Status Network](https://status.network/).  
This repo contains genesis files as well as the setup script to get started.

Good luck!
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>

# How to use it?
1. Run `git clone https://github.com/status-im/status-l2-rpc-tools.git`
2. Find the chain id of the Status Network you wish to run RPC for in the table bellow or on [chainlist](https://chainlist.org).
4. Run `mkdir status-l2-rpc`
3. Run `cp ./status-l2-rpc-tools/CHAIN_ID/setup.sh ./status-l2-rpc/setup.sh`
> [!IMPORTANT]  
> Replace CHAIN_ID with the one you picked in step 2
4. Run `cd status-l2-rpc`
5. Run `chmod +x ./setup.sh`
6. Run `./setup.sh`
7. Follow further instructions from the script output

# Chains
| Name                   | Chain ID   |
|------------------------|------------|
| Status Network Sepolia | 1660990954 |