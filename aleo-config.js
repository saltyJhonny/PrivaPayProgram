import dotenv from 'dotenv';
dotenv.config();

export default {
  accounts: [process.env.ALEO_PRIVATE_KEY],
  mode: 'execute',
  mainnet: {},
  networks: {
    testnet: {
      endpoint: 'https://api.explorer.provable.com/v1',
      accounts: [
        process.env.ALEO_PRIVATE_KEY,
      ],
      priorityFee: 0.01
    },
    mainnet: {
      endpoint: 'https://api.explorer.aleo.org/v1',
      accounts: [process.env.ALEO_PRIVATE_KEY_MAINNET],
      priorityFee: 0.001
    }
  },
  defaultNetwork: 'testnet'
};
