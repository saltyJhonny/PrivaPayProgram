import { ExecutionMode, js2leo } from "@doko-js/core";
import { Privapay_v0003Contract } from "../artifacts/js/privapay_v0003";

const mode = ExecutionMode.SnarkExecute;

const privapay = new Privapay_v0003Contract({mode: mode});
const dao = new 


const TIMEOUT = 300000_000;
const company_id = BigInt(1);
const company_name = BigInt(1234);





describe("Payment Contract Test", () => {

    const [aleouser1, aleouser2, aleouser3, aleoUser4] = privapay.getAccounts();

    const company1_Metatadata = {
    company_id: company_id,
    company_name: company_name,
    admin: aleouser1
    }

    test("deploy", async () => {
        const deployTx = await privapay.deploy();
        await deployTx.wait()
    }, TIMEOUT);

    test("deploy", async () => {
        const deployTx = await dao.deploy();
        await deployTx.wait()
    }, TIMEOUT);

    // test("Register company", async () => {
    //     const tx = await paymentV001.register_company(company_id, company_name);
    //     await tx.wait();
    //     expect(paymentV001.registered_company(company_id)).toEqual(company1_Metatadata);
    // }, TIMEOUT);


    // describe("update company", () => {
    //     const new_company_name = BigInt(5678);

    //     const new_company_Metatadata = {
    //         company_id: company_id,
    //         company_name: new_company_name,
    //         admin: aleouser1
    //     }

    //     test("only company admin can Update company data", async () => {
    //         paymentV001.connect(aleoUser4);
    //         const tx = await paymentV001.update_company(company_id, new_company_name, aleouser1);
    //         await expect(tx.wait()).rejects.toThrow();
    //     }, TIMEOUT);

    //     test("Update company happy flow", async () => {
    //         paymentV001.connect(aleouser1);
    //         const tx = await paymentV001.update_company(company_id, new_company_name, aleouser1);
    //         await tx.wait();
    //         expect(paymentV001.registered_company(company_id)).toEqual(company1_Metatadata);
    //     }, TIMEOUT);
    // });


    // describe("update company", () => {
    //     const new_company_name = BigInt(5678);

    //     const new_company_Metatadata = {
    //         company_id: company_id,
    //         company_name: new_company_name,
    //         admin: aleouser1
    //     }

    //     test("only company admin can Update company data", async () => {
    //         paymentV001.connect(aleoUser4);
    //         const tx = await paymentV001.update_company(company_id, new_company_name, aleouser1);
    //         await expect(tx.wait()).rejects.toThrow();
    //     }, TIMEOUT);

    //     test("Update company happy flow", async () => {
    //         paymentV001.connect(aleouser1);
    //         const tx = await paymentV001.update_company(company_id, new_company_name, aleouser1);
    //         await tx.wait();
    //         expect(paymentV001.registered_company(company_id)).toEqual(company1_Metatadata);
    //     }, TIMEOUT);
    // });




    

    // test("deploy", async () => {}, TIMEOUT);

});