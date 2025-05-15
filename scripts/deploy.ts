import { ExecutionMode } from "@doko-js/core";
import { Privapay_v0001Contract } from "../artifacts/js/privapay_v0001";

const contract = new Privapay_v0001Contract({
  mode: ExecutionMode.SnarkExecute
});

async function main() {
  const deployTx = await contract.deploy();
  await deployTx.wait();
  console.log("Contract deployed successfully");
}
main()
  .then(() => {
    console.log("Deployment script completed successfully");
  }
  )
  .catch((error) => {
    console.error("Error during deployment:", error);
  }
  );
