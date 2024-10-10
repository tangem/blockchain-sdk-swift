# WebSocket Chain Metadata Fetcher

This script connects to a blockchain WebSocket endpoint (e.g., Energy Web X) using the Polkadot API and fetches metadata information, including details about the `Balances` pallet and its `transfer` call.

## Prerequisites

- **Node.js**: You need to have Node.js installed on your system. If Node.js is not installed, you can install it using Homebrew:

    ```bash
    brew install node
    ```

## Usage

1. Make the wrapper script executable:

    ```bash
    chmod +x parse
    ```

2. Run the script with the WebSocket URL as an argument:

    ```bash
    ./parse <url>
    ```

### Example

To fetch metadata from the Energy Web X network, run the script like this:

```bash
./parse wss://wnp-rpc.mainnet.energywebx.com
