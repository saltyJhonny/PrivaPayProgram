import credits.aleo;
import token_registry.aleo;

program privapay_v001.aleo {

  record Employee {
        company_id: field,
        employee_id: field,
        owner: address,
        amount: u128,
        token_id: field,
        start_date: u32,
        end_date: u32,
        claimable_salary: u128
  }

  record EmpRecForAdmin {
        owner: address,
        company_id: field,
        employee_id: field,
        employee_address: address,
        amount: u128
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

    struct CompanyOwner {
    account: address,
    company_id: field
  }


 mapping registered_company: field => CompanyMetadata;

 mapping is_employee_registered: field => bool;
 mapping is_employee_active: field => bool;

 mapping total_claimed: field => u128;
 
 mapping latest_claim: field => u32;

 mapping admin_signature: field => signature;

  const HR_ROLE: u8 = 1u8;
  mapping roles: field => u8; // hash(token_id, account) => role


  async transition register_company(public company_id: field,public company_name: u128) -> Future {
    let company: CompanyMetadata = CompanyMetadata {
      company_id: company_id,
      company_name: company_name,
      admin: self.caller
    };

    
    return finalize_register_company(company);
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

  async transition add_employee(
    company_id: field,
    employee_id: field,
    employee_address: address,
    salary: u128,
    token_id: field,
    start_period: u32,
    end_period: u32,
  ) -> (Employee, EmpRecForAdmin, Future)
  { 

    let salary_transfer: Future = token_registry.aleo/transfer_public_as_signer(token_id, self.address, salary);
    assert(end_period > start_period);
    let employee: Employee = Employee {
      company_id: company_id,
      employee_id: employee_id,
      owner: employee_address,
      amount: salary,
      token_id: token_id,
      start_date: start_period,
      end_date: end_period,
      claimable_salary: salary
      };
    let for_admin: EmpRecForAdmin = EmpRecForAdmin {
      owner: self.signer,
      company_id: company_id,
      employee_id: employee_id,
      employee_address: employee_address,
      amount: salary
    };

      let employee_hash: field = BHP256::hash_to_field(EmployeeInfo {
      company_id: company_id,
      employee_id: employee_id,
      employee_address: employee_address,
      token_id: token_id
      });
    return (employee, for_admin, finalize_add_employee(company_id, employee_hash, start_period, end_period, self.signer, salary_transfer));  
  }

  async function finalize_add_employee(
    company_id: field,
    employee_hash: field,
    start_date: u32,
    end_date: u32,
    caller: address,
    f0: Future
  ) {
    f0.await();
    // Check if the registered_company is registered
    assert(registered_company.contains(company_id));
    let company: CompanyMetadata = registered_company.get(company_id);

    // Check if the caller is the admin of the company
    assert_eq(company.admin, caller); 

    // // Check if the caller has the HR role
    // let caller_hash: field = BHP256::hash_to_field(CompanyOwner {
    //   account: caller,
    //   company_id: company_id
    // });
    // assert(roles.contains(caller_hash));

    // check if start height is greater or equal to the current height
    let currrent_height: u32 = block.height;
    assert(start_date >= currrent_height); 

    // check if employee is already registered
    let is_registered_already: bool = is_employee_registered.get_or_use(employee_hash, false);
    assert_eq(is_registered_already, false);
    is_employee_registered.set(employee_hash, true);

    // check if employee is already active
    let is_active: bool = is_employee_active.get(employee_hash);
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
    previous_record: Employee
  ) -> (Employee, EmpRecForAdmin, Future) {

    let updated_employee: Employee = Employee {
      company_id: previous_record.company_id,
      employee_id: previous_record.employee_id,
      owner: previous_record.owner,
      amount: salary,
      token_id: token_id,
      start_date: start_period,
      end_date: end_period,
      claimable_salary: salary + previous_record.claimable_salary
    };

    let for_admin: EmpRecForAdmin = EmpRecForAdmin {
      owner: admin,
      company_id: previous_record.company_id,
      employee_id: previous_record.employee_id,
      employee_address: admin,
      amount: salary
    };

    let employee_hash: field = BHP256::hash_to_field(EmployeeInfo {
      company_id: previous_record.company_id,
      employee_id: previous_record.employee_id,
      employee_address: previous_record.owner,
      token_id: token_id
      });

    return (updated_employee,for_admin,finalize_update_employee(previous_record.company_id, self.caller, employee_hash, admin, signed_by_admin));
  }

  async function finalize_update_employee(
    company_id: field,
    caller: address,
    employee_hash: field,
    admin: address,
    signed_by_admin: signature
  ) {
   // Check if the employee is already registered
    assert(registered_company.contains(company_id));

    let company: CompanyMetadata = registered_company.get(company_id);
    assert_eq(company.admin, admin);
    let status: bool = signed_by_admin.verify(company.admin, employee_hash);
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
      owner: employee_record.owner,
      amount: employee_record.amount,
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
    assert_eq(is_employee_registered.get(employee_hash), true);
    assert_eq(is_employee_active.get(employee_hash), true);

    let last_claimed_by_user: u32 = latest_claim.get_or_use(employee_hash, start_date);

    let last_claimed_amount: u128 = total_claimed.get_or_use(employee_hash, 0u128);

    total_claimed.set(employee_hash, last_claimed_amount + withdraw_amount);

    let withdrawable_amount: u128 = (((block.height - last_claimed_by_user) / (end_date - start_date)) as u128) * salary;

    assert(withdrawable_amount >= withdraw_amount);

    // set latest height after claimimg
    latest_claim.set(employee_hash, block.height);
  }

} 