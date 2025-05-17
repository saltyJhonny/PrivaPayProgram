import { ExecutionMode } from "@doko-js/core";
import { Privacypay_dao_v0003Contract } from "../artifacts/js/privacypay_dao_v0003";

const dao = new Privacypay_dao_v0003Contract({ mode: ExecutionMode.SnarkExecute });

describe("DAO Contract Test", () => {


    test("deploy", async () => {
        const deployTx = await dao.deploy();
        await deployTx.wait()
    }, 300000_000);



})