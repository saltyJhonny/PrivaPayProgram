import token_registry.aleo;
import privapay_v0004.aleo;

program privacypay_dao_v0005.aleo {

    const ZERO_ADDRESS: address = aleo1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3ljyzc; 

    const TOTAL_PROPOSALS_INDEX: u32 = 0u32;

    mapping initial_fee: bool => u64;

    mapping proposals: u32 => Proposal;

    mapping votes: field => u128;

    mapping voters: u32 => u32;

    mapping is_voted: field => bool;


    mapping dao_token: field => field;

    mapping gov_token: u32 => field;


    mapping proposal_status: u32 => u8;

    mapping latest_proposal_id: bool => u32;

    mapping admin: address => bool;

    const ACTIVE: u8 = 0u8;
    const ACCEPTED: u8 = 1u8;
    const REJECTED: u8 = 2u8;
    const CANCELLED: u8 = 3u8;

    const AUTHORIZED_UNTILL: u32 = 4294967295u32;

    struct VoteAcceptance {
        id: u32,
        acceptance: bool
    }

    struct Proposal {
        id: u32,
        company_id: field,
        time_limit: u32,
        detail_hash: [field;2],
        proposer: address
    }

    struct ProposalVote {
        proposal_id: u32,
        voter: address
    }

    async transition initialize(fee: u64) -> Future{
        return finalize_initialize(fee, self.caller);
    }

    async function finalize_initialize(fee: u64, from: address) {
        admin.set(from, true);
        initial_fee.set(true, fee);
    }


    async transition register(company_id: field, token_id: field,  public name: u128, symbol: u128, decimals: u8, max_supply: u128, external_authorization_required: bool, external_authorization_party: address) -> Future {
        let register_in_registry: Future = token_registry.aleo/register_token(token_id, name, symbol, decimals, max_supply, external_authorization_required, external_authorization_party);
        return finalize_register(company_id, token_id, self.caller, register_in_registry);
    }

    async function finalize_register(company_id: field, token_id: field, from: address, f0: Future) {
        f0.await();
        let company: CompanyMetadata = privapay_v0004.aleo/registered_company.get(company_id);
        assert_eq(company.admin, from);
        dao_token.set(company_id, token_id);
    }


    async transition give_vote_power(company_id: field, token_id: field, receiver: address, amount: u128) ->  (token_registry.aleo/Token, Future) {
        let mint: (token_registry.aleo/Token, Future) = token_registry.aleo/mint_private(token_id, receiver, amount, false, AUTHORIZED_UNTILL);
        return (mint.0, finalize_give_vote_power(company_id, token_id, self.caller, mint.1));
    }

    async function finalize_give_vote_power(company_id: field, token_id: field, from: address, f0: Future) {
        f0.await();
        let company: CompanyMetadata = privapay_v0004.aleo/registered_company.get(company_id);
        assert_eq(company.admin, from);
        assert_eq(dao_token.get(company_id), token_id);
    }

    async transition propose(public id: u32, company_id: field, time_limit: u32, detail_hash: [field;2], token_record: token_registry.aleo/Token) -> Future{
        let from: address = self.caller;
        assert_neq(from, ZERO_ADDRESS);
        let proposal: Proposal = Proposal {
            id: id,
            company_id: company_id,
            time_limit: time_limit,
            detail_hash: detail_hash,
            proposer: from
        };
        return finalize_propose(id, company_id, proposal,time_limit, token_record.token_id);
    }

    async function finalize_propose(proposal_id: u32, company_id:field, proposal: Proposal, time_limit: u32, token_id:field) {

        assert_eq(dao_token.get(company_id), token_id);

        let latest_id: u32 = latest_proposal_id.get_or_use(true, 0u32) + 1u32; // todo 

        assert_eq(proposal_id, latest_id);

        // Store the proposal hash
        Mapping::set(proposals, proposal_id, proposal);

        Mapping::set(proposal_status, proposal_id, ACTIVE);

        Mapping::set(latest_proposal_id, true, proposal_id);
        Mapping::set(gov_token, proposal_id, token_id);
    }


    async transition vote_proposal(public proposal_id: u32, company_id:field, token_record: token_registry.aleo/Token, accept: bool) -> Future{
        let from: address = self.caller;
        assert_neq(from, ZERO_ADDRESS);
        let voting_power: u128 = token_record.amount;
        let vote: field = BHP256::hash_to_field(ProposalVote {
            proposal_id: proposal_id,
            voter: from
        });
        return (finalize_vote( proposal_id, company_id,vote, token_record.token_id, token_record.amount, voting_power, accept));
    }

    async function finalize_vote(proposal_id: u32, company_id:field, vote: field, token_id: field, amount: u128, voting_power: u128, acceptance: bool) {
        assert_eq(is_voted.get_or_use(vote, false), false);
        assert_eq(dao_token.get(company_id), token_id);
        assert_eq(gov_token.get(proposal_id), token_id);
        let status: u8 = proposal_status.get(proposal_id);

        assert_eq(status, ACTIVE);
        let proposal: Proposal = proposals.get(proposal_id);

        let yes_voting: VoteAcceptance = VoteAcceptance {
                id: proposal_id,
                acceptance: true
        };

        let yes_hash: field = BHP256::hash_to_field(yes_voting);

        let no_voting: VoteAcceptance = VoteAcceptance {
                id: proposal_id,
                acceptance: false
        };
        let no_hash: field = BHP256::hash_to_field(no_voting);

        let total_votes: u128 = acceptance ? votes.get_or_use(yes_hash, 0u128) : votes.get_or_use(no_hash, 0u128);

        if (acceptance) {
            votes.set(yes_hash, total_votes + amount);
        } else {
            votes.set(no_hash, total_votes + amount);
        }

        voters.set(proposal_id, voters.get_or_use(proposal_id, 0u32) + 1u32);

        is_voted.set(vote, true);

        assert(block.height < proposal.time_limit);
    }

    async transition cancel_proposal(proposal_id: u32) -> Future{
        let from: address = self.caller;
        assert_neq(from, ZERO_ADDRESS);
        return finalize_cancel_proposal(proposal_id, self.caller);
    }

    async function finalize_cancel_proposal(proposal_id: u32, from: address) {        
        let proposal: Proposal = proposals.get(proposal_id);
        let company: CompanyMetadata = privapay_v0004.aleo/registered_company.get(proposal.company_id);
        assert(from == proposal.proposer || from == company.admin);
        proposal_status.set(proposal_id, CANCELLED);
    }


    async transition close_proposal(proposal_id: u32, company_id: field, acceptanace: bool) -> Future{
        let from: address = self.caller;
        assert_neq(from, ZERO_ADDRESS);
        return finalize_close_proposal(proposal_id, company_id, self.caller, acceptanace);
    }

    async function finalize_close_proposal(proposal_id: u32, company_id: field, from: address, acceptanace: bool) {        
        let proposal: Proposal = proposals.get(proposal_id);

        let company: CompanyMetadata = privapay_v0004.aleo/registered_company.get(company_id);
        assert_eq(company.admin, from);

        assert(block.height >= proposal.time_limit);
        assert(proposal_status.get(proposal_id) == ACTIVE);

        if acceptanace {
            proposal_status.set(proposal_id, ACCEPTED);
        } else {
            proposal_status.set(proposal_id, REJECTED);
        }
    }

}