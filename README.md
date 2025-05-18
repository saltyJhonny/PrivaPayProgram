# 🛡️ PrivacyPay Protocol on Aleo

**PrivacyPay** is a privacy-preserving, decentralized payroll and governance system built on the [Aleo blockchain](https://aleo.org). The protocol enables companies to manage employee compensation and internal governance through on-chain transitions while maintaining confidentiality using zero-knowledge proofs.

## 📚 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Payroll Module – `privapay_v0004.aleo`](#-payroll-module--privapay_v0004aleo)
- [Governance Module – `privacypay_dao_v0005.aleo`](#-governance-module--privacypay_dao_v0005aleo)
- [Workflows](#-workflows)
- [Security](#-security)
- [Dependencies](#-dependencies)
- [License](#-license)
- [Author](#-author)

---

## 🧩 Overview

**PrivacyPay** introduces a modular protocol for managing:
- **Payroll**: Register companies, onboard employees, assign and update salaries, handle withdrawals.
- **Governance**: Propose changes, cast token-weighted votes, and manage proposals securely.

This system is ideal for decentralized or remote organizations seeking blockchain transparency while preserving employee privacy.

---

## 🏗️ Architecture

```text
                              +----------------------+
                              |    Aleo Blockchain   |
                              +----------------------+
                                         |
         +-------------------------------+------------------------------+
         |                                                              |
+---------------------+                                 +---------------------------+
|  Payroll Contract    |                                 |  DAO Governance Contract  |
|  privapay_v0004.aleo |                                 | privacypay_dao_v0005.aleo |
+---------------------+                                 +---------------------------+
| - Register company  |                                 | - Register DAO token      |
| - Add employees     |                                 | - Create proposals        |
| - Allocate salary   |                                 | - Vote using DAO tokens   |
| - Withdraw salary   |                                 | - Close/cancel proposals  |
+---------------------+                                 +---------------------------+
```

---

## 🚀 Features

### ✅ Payroll (v0004)

- Company registration & admin assignment
- Employee onboarding with salary, token, and date range
- Signature-based salary updates
- Salary withdrawals based on block height
- Token-based payments using `token_registry.aleo`
- Name-based identity mapping using `ans_registrar_usd2.aleo`

### ✅ Governance (v0005)

- DAO token registration per company
- Mint voting power to addresses
- Create proposals with expiration
- Vote with DAO tokens (1 token = 1 vote)
- Enforced voting cutoff via `block.height`
- Double-voting prevention via hashed vote records
- Close or cancel proposals by admin

---

## 💼 Payroll Module – `privapay_v0004.aleo`

### Records
- `CompanyMetadata`: ID, name, and admin address
- `Employee`: Full employment record including salary and time range
- `EmpRecForAdmin`: View for administrative reporting

### Transitions
- `register_company(company_id, company_name)`
- `add_employee(...)`
- `update_employee(...)`
- `generate_signature(...)`
- `withdraw_salary(employee_record, amount)`

### Internal Safeguards
- Asserts company exists and admin matches
- Verifies start and end periods
- Verifies salary withdrawal is within claimable range
- Prevents duplicate employee entries

---

## 🗳️ Governance Module – `privacypay_dao_v0005.aleo`

### Structures
- `Proposal`: Metadata and hashed details for a proposal
- `ProposalVote`: Unique vote hash per user/proposal
- `VoteAcceptance`: Used to tally yes/no votes separately

### Transitions
- `initialize(fee)`
- `register(company_id, token_id, ...)` → Link DAO token to company
- `give_vote_power(company_id, token_id, receiver, amount)`
- `propose(...)` → Add new governance proposal
- `vote_proposal(...)` → Vote using DAO tokens
- `close_proposal(...)` → Admin closes proposal after expiration
- `cancel_proposal(...)` → Cancel by proposer or admin

### Proposal Lifecycle
| Status     | Code |
|------------|------|
| Active     | 0    |
| Accepted   | 1    |
| Rejected   | 2    |
| Cancelled  | 3    |

---

## 🔁 Workflows

### 💼 Payroll Example

```aleo
// Register a company
register_company("company_xyz", 123456);

// Add an employee
add_employee("company_xyz", 101, "aleo1...", 10000, "token_xyz", 200, 300, ["John", "Doe", "", ""], timestamp, usd_price);

// Employee withdraws salary
withdraw_salary(employee_record, 2500);
```

### 🗳️ DAO Voting Example

```aleo
// Initialize DAO and set initial fee
initialize(500);

// Register DAO token
register("company_xyz", "dao_token", "DAO", "D", 0u8, 1000000u128, false, ZERO_ADDRESS);

// Mint vote power
give_vote_power("company_xyz", "dao_token", voter_address, 100);

// Submit proposal
propose(1u32, "company_xyz", block.height + 100, [hash1, hash2], token_record);

// Vote on proposal
vote_proposal(1u32, "company_xyz", token_record, true);

// Close proposal post-deadline
close_proposal(1u32, "company_xyz", true);
```

---

## 🔐 Security

- ✔️ Double-voting prevention using vote hashes
- ✔️ Block height-based time restrictions
- ✔️ Signature validation for salary updates
- ✔️ DAO token validation for proposal creation and voting
- ✔️ Admin-only authorization for sensitive transitions
- ✔️ Enforced proposal ID tracking to avoid overwrites

---



## 🙌 Contributions

Pull requests, discussions, and audits are welcome.  
Let’s build the future of payroll and governance — private, decentralized, and secure.