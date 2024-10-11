const { ApiPromise, WsProvider, HttpProvider } = require('@polkadot/api');

async function main() {
  // Get the WebSocket or HTTP/HTTPS URL from command-line arguments
  const url = process.argv[2];

  if (!url) {
    console.error("Please provide a WebSocket or HTTP/HTTPS URL as an argument.");
    process.exit(1);
  }

  let provider;

  // Check if the URL starts with ws:// or wss:// for WebSocket, or http:// or https:// for HTTP
  if (url.startsWith('ws://') || url.startsWith('wss://')) {
    console.log("WebSocket URL detected. Using WsProvider...");
    provider = new WsProvider(url);
  } else if (url.startsWith('http://') || url.startsWith('https://')) {
    console.log("HTTP/HTTPS URL detected. Using HttpProvider...");
    provider = new HttpProvider(url);
  } else {
    console.error("Invalid URL schema. Please provide a valid WebSocket (ws://, wss://) or HTTP/HTTPS (http://, https://) URL.");
    process.exit(1);
  }

  // Connect to the chain using the appropriate provider
  const api = await ApiPromise.create({ provider });

  // Fetch runtime version
  const metadata = await api.rpc.state.getMetadata();
  const pallets = metadata.asLatest.pallets;
  const lookup = metadata.asLatest.lookup;

  console.log(`Metadata Version: ${metadata.version}`);

  // Find the 'balances' pallet
  const balancesPallet = pallets.find(pallet => pallet.name.toString() === 'Balances');
  if (balancesPallet) {
    const palletIndex = balancesPallet.index.toNumber();

    if (balancesPallet.calls.isSome) {
      const callTypeId = balancesPallet.calls.unwrap().type;
      const callType = lookup.getSiType(callTypeId);

      // Find the 'transfer' call
      let transferCall = callType.def.asVariant.variants.find(call => call.name.toString() === 'transfer');
      if (!transferCall) {
        transferCall = callType.def.asVariant.variants.find(call => call.name.toString() === 'transfer_allow_death');
      }

      if (transferCall) {
        const callIndex = callType.def.asVariant.variants.indexOf(transferCall);
        const fullCallIndex = `${palletIndex.toString(16).padStart(2, '0')}${callIndex.toString(16).padStart(2, '0')}`;

        console.log(`Transfer Call Index: 0x${fullCallIndex}`);
      }
    } else {
      console.log("The balances pallet has no calls.");
    }
  } else {
    console.log("Balances pallet not found.");
  }

  // Disconnect from the API
  await api.disconnect();
}

main().catch(console.error);