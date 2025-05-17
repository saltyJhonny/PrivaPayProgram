import token_registry.aleo;
import credits.aleo;
import ans_registrar_usd2.aleo;

program privapay_v0003.aleo {

  record Employee {
        company_id: field,
        employee_id: field,
        employee_name_field: field,
        owner: address,
        amount: u128,
        token_id: field,
        start_date: u32,
        end_date: u32,
        record_type: u8,
        claimable_salary: u128
  }

  record EmpRecForAdmin {
        owner: address,
        company_id: field,
        employee_id: field,
        employee_name_field: field,
        record_type: u8,
        amount: u128
  }

  struct EmployeeSignatureInfo {
        company_id: field,
        employee_id: field,
        employee_address: address,
        token_id: field,
        salary: u128,
        start_period: u32,
        end_period: u32
  }

  struct EmployeeInfo {
        company_id: field,
        employee_id: field,
        employee_address: address,
        token_id: field,
  }


  struct CompanyMetadata {
    company_id: field,
    company_name: u128,
    admin: address,
  }

  record CompanyOwner {
    company_id: field,
    record_type: u8,
    owner: address
  }

  const COMPANY_OWNER_RECORD_TYPE: u8 = 0u8;
  const EMPLOYEE_RECORD_TYPE: u8 = 1u8;
  const EMPLOYEE_RECORD_FOR_ADMIN: u8 = 2u8;


 mapping registered_company: field => CompanyMetadata;

 mapping is_employee_registered: field => bool;
 mapping is_employee_active: field => bool;

 mapping total_claimed: field => u128;
 
 mapping latest_claim: field => u32;

 mapping admin_signature: field => signature;

 const PARENT: field = 559532657689873513833888656958509165446284001025178663602770230581478239512field;



  async transition register_company(public company_id: field,public company_name: u128) -> (CompanyOwner,Future) {
    let company: CompanyMetadata = CompanyMetadata {
      company_id: company_id,
      company_name: company_name,
      admin: self.caller
    };

    let company_owner: CompanyOwner = CompanyOwner {
      company_id: company.company_id,
      record_type: COMPANY_OWNER_RECORD_TYPE,
      owner: self.caller
    };

    
    return (company_owner, finalize_register_company(company));
  }

  async function finalize_register_company(company: CompanyMetadata) {
    // Make sure company doesn't already exist
    let company_exists: bool = registered_company.contains(company.company_id);
    assert_eq(company_exists, false);
    // Set new company
    registered_company.set(company.company_id, company);
  }

  async transition update_company(
    public company_id: field,
    public company_name: u128,
    public admin: address
  ) -> Future {
    return finalize_update_company(company_id, company_name, admin, self.caller);
  }

  async function finalize_update_company(
    company_id: field,
    company_name: u128,
    admin: address,
    caller: address
  ) {
    let company: CompanyMetadata = registered_company.get(company_id);
    assert_eq(caller, company.admin);

    let new_metadata: CompanyMetadata = CompanyMetadata {
      company_id: company.company_id,
      company_name: company_name,
      admin: admin
    };
    registered_company.set(company_id, new_metadata);
  }


  function calc_name_field(name: [u128; 4], parent: field) -> field {
        let full_name: Name = Name {
            name: name,
            parent: parent
        };
      return Poseidon2::hash_to_field(full_name);
  }

  async transition add_employee(
    company_id: field,
    employee_id: field,
    employee_address: address,
    salary: u128,
    token_id: field,
    start_period: u32,
    end_period: u32,
    name: [u128; 4],
    timestamp: u64,
    usd_price: u64,
  ) -> (Employee, EmpRecForAdmin, Future)
  { 
    let set_employee_ans: Future = ans_registrar_usd2.aleo/register_fld_public(name, PARENT, employee_address, timestamp, usd_price);
    let employee_field: field = calc_name_field(name, PARENT);
    let salary_transfer: Future = token_registry.aleo/transfer_public_as_signer(token_id, self.address, salary);
    assert(end_period > start_period);
    let employee: Employee = Employee {
      company_id: company_id,
      employee_id: employee_id,
      employee_name_field: employee_field,
      owner: employee_address,
      amount: salary,
      token_id: token_id,
      record_type: EMPLOYEE_RECORD_TYPE,
      start_date: start_period,
      end_date: end_period,
      claimable_salary: salary
      };
    let for_admin: EmpRecForAdmin = EmpRecForAdmin {
      owner: self.signer,
      company_id: company_id,
      employee_id: employee_id,
      employee_name_field: employee_field, 
      record_type: EMPLOYEE_RECORD_FOR_ADMIN,
      amount: salary
    };

      let employee_hash: field = BHP256::hash_to_field(EmployeeInfo {
      company_id: company_id,
      employee_id: employee_id,
      employee_address: employee_address,
      token_id: token_id
      });
    return (employee, for_admin, finalize_add_employee(company_id, employee_hash, start_period, end_period, self.signer, set_employee_ans, salary_transfer));  
  }

  async function finalize_add_employee(
    company_id: field,
    employee_hash: field,
    start_date: u32,
    end_date: u32,
    caller: address,
    f0: Future,
    f1: Future
  ) {
    f0.await();
    f1.await();
    // Check if the registered_company is registered
    assert(registered_company.contains(company_id));
    let company: CompanyMetadata = registered_company.get(company_id);

    // Check if the caller is the admin of the company
    assert_eq(company.admin, caller); 

    // check if start height is greater or equal to the current height
    let currrent_height: u32 = block.height;
    assert(start_date >= currrent_height); 

    // check if employee is already registered
    let is_registered_already: bool = is_employee_registered.get_or_use(employee_hash, false);
    assert_eq(is_registered_already, false);
    is_employee_registered.set(employee_hash, true);

    // check if employee is already active
    let is_active: bool = is_employee_active.get_or_use(employee_hash,false);
    assert_eq(is_active, false);
    is_employee_active.set(employee_hash, true);
  }

  async transition generate_signature(
    company_id: field,
    employee_id: field,
    employee_address: address,
    salary: u128,
    token_id: field,
    start_period: u32,
    end_period: u32,
    signed_by_admin: signature,
  ) -> Future {
      let employee_hash: field = BHP256::hash_to_field(EmployeeInfo {
      company_id: company_id,
      employee_id: employee_id,
      employee_address: employee_address,
      token_id: token_id
      });

    return finalize_generate_signature(signed_by_admin, employee_hash, company_id, self.signer);
  }

  async function finalize_generate_signature(
    signed_by_admin: signature,
    employee_hash: field,
    company_id: field,
    caller: address
  ) {
     assert(registered_company.contains(company_id));
    let company: CompanyMetadata = registered_company.get(company_id);

    // Check if the caller is the admin of the company
    assert_eq(company.admin, caller); 
    admin_signature.set(employee_hash, signed_by_admin);

  }
  

  async transition update_employee(
    salary: u128,
    token_id: field,
    start_period: u32,
    end_period: u32,
    signed_by_admin: signature,
    admin: address,
    name: [u128; 4],
    previous_record: Employee
  ) -> (Employee, EmpRecForAdmin, Future) {

    let employee_field: field = calc_name_field(name, PARENT);

    let updated_employee: Employee = Employee {
      company_id: previous_record.company_id,
      employee_id: previous_record.employee_id,
      employee_name_field: employee_field,
      owner: previous_record.owner,
      amount: salary,
      token_id: token_id,
      record_type: EMPLOYEE_RECORD_TYPE,
      start_date: start_period,
      end_date: end_period,
      claimable_salary: salary + previous_record.claimable_salary
    };

    let for_admin: EmpRecForAdmin = EmpRecForAdmin {
      owner: admin,
      company_id: previous_record.company_id,
      record_type: EMPLOYEE_RECORD_FOR_ADMIN,
      employee_id: previous_record.employee_id,
      employee_name_field: employee_field,
      amount: salary
    };

    let employee_hash: field = BHP256::hash_to_field(EmployeeInfo {
      company_id: previous_record.company_id,
      employee_id: previous_record.employee_id,
      employee_address: previous_record.owner,
      token_id: token_id
      });
    
    let signed_hash:field = BHP256::hash_to_field(EmployeeSignatureInfo {
      company_id: previous_record.company_id,
      employee_id: previous_record.employee_id,
      employee_address: previous_record.owner,
      token_id: token_id,
      salary: salary,
      start_period: start_period,
      end_period: end_period
      });

    return (updated_employee,for_admin,finalize_update_employee(previous_record.company_id, self.caller, signed_hash, admin, signed_by_admin));
  }

  async function finalize_update_employee(
    company_id: field,
    caller: address,
    signed_hash: field,
    admin: address,
    signed_by_admin: signature
  ) {
   // Check if the employee is already registered
    assert(registered_company.contains(company_id));

    let company: CompanyMetadata = registered_company.get(company_id);
    assert_eq(company.admin, admin);
    let status: bool = signed_by_admin.verify(company.admin, signed_hash);
    assert_eq(status, true);
  }


  async transition withdraw_salary(
    employee_record: Employee,
    withdraw_amount: u128,
  ) -> (token_registry.aleo/Token, Employee, Future) {
    let employee_hash: field = BHP256::hash_to_field(EmployeeInfo {
      company_id: employee_record.company_id,
      employee_id: employee_record.employee_id,
      employee_address: employee_record.owner,
      token_id: employee_record.token_id
    });

    let employee: Employee = Employee {
      company_id: employee_record.company_id,
      employee_id: employee_record.employee_id,
      employee_name_field: employee_record.employee_name_field,
      owner: employee_record.owner,
      amount: employee_record.amount,
      record_type: employee_record.record_type,
      token_id: employee_record.token_id,
      start_date: employee_record.start_date,
      end_date: employee_record.end_date,
      claimable_salary: employee_record.claimable_salary - withdraw_amount
    };

    let withdraw: (token_registry.aleo/Token, Future) = token_registry.aleo/transfer_public_to_private(employee_record.token_id, employee_record.owner, withdraw_amount, false);

    assert(withdraw_amount < employee_record.amount);
    return (withdraw.0, employee, finalize_withdraw_salary(employee_hash,  employee_record.company_id, employee_record.start_date, employee_record.end_date, employee_record.amount, withdraw_amount, withdraw.1));
  }

  async function finalize_withdraw_salary(employee_hash: field, company_id: field, start_date: u32, end_date: u32, salary: u128, withdraw_amount: u128, f0: Future) {
    f0.await();
    // Check if the company is already registered
    assert(registered_company.contains(company_id));

    // check if employee is registered
    assert(is_employee_registered.get(employee_hash));
    assert(is_employee_active.get(employee_hash));

    let last_claimed_by_user: u32 = latest_claim.get_or_use(employee_hash, start_date);

    let total_claimed_amount: u128 = total_claimed.get_or_use(employee_hash, 0u128);

    total_claimed.set(employee_hash, total_claimed_amount + withdraw_amount);

    let withdrawable_amount: u128 = ((block.height - last_claimed_by_user) as u128 * salary) /  (end_date - start_date) as u128 ;

    assert(withdrawable_amount >= withdraw_amount);

    // set latest height after claimimg
    latest_claim.set(employee_hash, block.height);
  }

} 