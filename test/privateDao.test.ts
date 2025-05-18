import { ExecutionMode, leo2js } from "@doko-js/core";
import { Privacypay_dao_v0005Contract } from "../artifacts/js/privacypay_dao_v0005";
import { Token_registryContract } from "../artifacts/js/token_registry";
import { js2leo as js2leoCommon } from '@doko-js/core';
import { leo2js as leo2jsCommon } from '@doko-js/core';
import { hash } from "aleo-hasher";


const mode = ExecutionMode.SnarkExecute;

const dao = new Privacypay_dao_v0005Contract({ mode: ExecutionMode.SnarkExecute });
const token_registry = new Token_registryContract({ mode: mode });

// const hashStruct = (struct: bigint): bigint => {
//   const structString = js2leoCommon.json(struct)
//   console.log(structString);
//   const structHash = hash("bhp256", structString, "field");
//   const hashBigInt = leo2jsCommon.field(structHash);
//   return hashBigInt
// }

const [aleoUser1] = token_registry.getAccounts()

const token_name = BigInt('1462356597207352999936')
const token_symbol = BigInt("1329873231") 
const token_decimals = 6
const token_max_supply = BigInt("18446744073709551615")
const tokenID = leo2js.field(hash('bhp256', token_name.toString() + "u128", 'field'));
const compay_id =  BigInt(1)
const external_authorization_required = false
const receiver = "aleo19rvznap09ngdjvgjgydyy7g2gt5ga8ky4pj8yxk48600mpdy6g9s7etzvp";
const receiver2 = "aleo12586w8v50dl70ku7rltpwdrmht3eaa6v0frg6669kjs49t6x5q9sfllgts";
const receiver3 = "aleo1wfaqpfc57m0wxmr9l6r8a5g95c0cthe54shzmcyu6wf6tqvady9syt27xt";
const amount = BigInt(100);
const authorized_until = 4294967295;

describe("DAO Contract Test", () => {


    // test("deploy", async () => {
    //     const deployTx = await dao.deploy();
    //     await deployTx.wait()
    // }, 300000_000);


    // test("register", async () => {
    //     const deployTx = await dao.register(compay_id, tokenID, token_name, token_symbol, token_decimals, token_max_supply, external_authorization_required, aleoUser1);
    //     await deployTx.wait()
    // }, 300000_000);

    // test("give voting power to employee1", async () => {
    //     const mintTx = await dao.give_vote_power(compay_id, tokenID, receiver, amount);
    //     await mintTx.wait();
    // }, 300000_000);

    // test("give voting powers to employee2", async () => {
    //     const mintTx = await dao.give_vote_power(compay_id, tokenID, receiver2, amount);
    //     await mintTx.wait();
    // }, 300000_000);

    test("give voting powers to admin", async () => {
        const mintTx = await dao.give_vote_power(compay_id, tokenID, receiver3, amount);
        await mintTx.wait();
    }, 300000_000);


})