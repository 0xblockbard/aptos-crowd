module crowdfund_addr::crowdfund {

    use std::signer;
    use std::event;
    use std::string::{String};

    use aptos_std::smart_table::{Self, SmartTable};
    
    use aptos_framework::aptos_account;
    use aptos_framework::object;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};

    // -----------------------------------
    // Seeds
    // -----------------------------------

    const APP_OBJECT_SEED: vector<u8> = b"CROWDFUND";

    // -----------------------------------
    // Errors
    // -----------------------------------

    const ERROR_NOT_ADMIN : u64                             = 1;
    const ERROR_NOT_CAMPAIGN_CREATOR : u64                  = 2;
    const ERROR_MIN_FUNDING_GOAL_NOT_REACHED : u64          = 3;
    const ERROR_MIN_DURATION_NOT_REACHED : u64              = 4;
    const ERROR_MIN_CONTRIBUTION_AMOUNT_NOT_REACHED : u64   = 5;
    const ERROR_INVALID_FUNDING_TYPE : u64                  = 6;
    const ERROR_CAMPAIGN_IS_OVER : u64                      = 7;
    const ERROR_CAMPAIGN_IS_NOT_OVER : u64                  = 8;
    const ERROR_CAMPAIGN_FUNDING_GOAL_NOT_REACHED : u64     = 9;
    const ERROR_CAMPAIGN_FUNDS_ALREADY_CLAIMED : u64        = 10;
    const ERROR_CONTRIBUTOR_NOT_FOUND : u64                 = 11;
    const ERROR_REFUND_AMOUNT_IS_ZERO : u64                 = 12;
    const ERROR_INVALID_NEW_FEE : u64                       = 13;

    // -----------------------------------
    // Constants
    // -----------------------------------

    // Funding Type constants
    const KEEP_IT_ALL_FUNDING_TYPE : u8             = 0;
    const ALL_OR_NOTHING_FUNDING_TYPE : u8          = 1;

    // Config defaults
    const DEFAULT_MIN_FUNDING_GOAL : u64            = 100_000_000; // 1 APT
    const DEFAULT_MIN_DURATION : u64                = 86400;       // 1 day
    const DEFAULT_MIN_CONTRIBUTION_AMOUNT : u64     = 100_000;     // 0.001 APT
    const DEFAULT_FEE : u64                         = 100;         // 1%

    // -----------------------------------
    // Structs
    // -----------------------------------

    /// Campaign Struct
    struct Campaign has key, store {
        
        creator : address, 
        name : String,
        description : String,
        image_url: String,
        funding_type: u8, 
        fee : u64, // changes to fees on module should not affect campaigns that are already live

        funding_goal : u64,
        contributed_amount : u64,
        claimed_amount : u64,
        leftover_amount : u64,
        refunded_amount : u64,
        duration : u64, 
        end_timestamp : u64,
        contributors: SmartTable<address, u64>, 
        
        claimed : bool,
        is_successful : bool
    }

    /// Campaigns Struct
    struct CreatorCampaigns has key, store {
        campaigns : SmartTable<u64, Campaign>, 
    }

    /// CampaignRegistry Struct
    struct CampaignRegistry has key, store {
        campaign_to_creator: SmartTable<u64, address>,
        next_campaign_id: u64,
    }

    /// Config Struct 
    struct Config has key, store {
        min_funding_goal : u64,
        min_duration : u64,
        min_contribution_amount : u64,
        fee : u64,
    }

    // Crowdfund Struct
    struct CrowdfundSigner has key, store {
        extend_ref : object::ExtendRef,
    }

    // AdminInfo Struct
    struct AdminInfo has key {
        admin_address: address,
    }

    // -----------------------------------
    // Events
    // -----------------------------------

    #[event]
    struct CampaignCreatedEvent has drop, store {
        campaign_id : u64,
        creator : address,
        name : String,
        description: String,
        image_url: String,
        funding_goal : u64,
        duration : u64,
        end_timestamp : u64,
        funding_type : u8,
    }

    #[event]
    struct CampaignUpdatedEvent has drop, store {
        campaign_id : u64,
        name : String,
        description: String,
        image_url: String
    }

    #[event]
    struct ContributionEvent has drop, store {
        campaign_id : u64,
        contributor : address,
        amount : u64,
    }

    #[event]
    struct ClaimFundsEvent has drop, store {
        campaign_id : u64,
        claim_total : u64,
    }

    #[event]
    struct RefundEvent has drop, store {
        campaign_id : u64,
        contributor : address,
        refund_amount : u64,
    }

    // -----------------------------------
    // Functions
    // -----------------------------------

    /// init module 
    fun init_module(admin : &signer) {

        let constructor_ref = object::create_named_object(
            admin,
            APP_OBJECT_SEED,
        );
        let extend_ref       = object::generate_extend_ref(&constructor_ref);
        let crowdfund_signer = &object::generate_signer(&constructor_ref);

        // Set CrowdfundSigner
        move_to(crowdfund_signer, CrowdfundSigner {
            extend_ref,
        });

        // Set AdminInfo
        move_to(crowdfund_signer, AdminInfo {
            admin_address: signer::address_of(admin),
        });

        // set default config
        move_to(crowdfund_signer, Config {
            min_funding_goal        : DEFAULT_MIN_FUNDING_GOAL, 
            min_duration            : DEFAULT_MIN_DURATION,
            min_contribution_amount : DEFAULT_MIN_CONTRIBUTION_AMOUNT, 
            fee                     : DEFAULT_FEE
        });

        // init campaign registry struct
        move_to(crowdfund_signer, CampaignRegistry {
            campaign_to_creator: smart_table::new(),
            next_campaign_id: 0,
        });
    }

    // ---------------
    // Admin functions 
    // ---------------

    public entry fun update_config(
        admin : &signer,
        new_min_funding_goal : u64,
        new_min_duration : u64,
        new_min_contribution_amount : u64,
        new_fee : u64
    ) acquires Config, AdminInfo {

        // get crowdfund signer address
        let crowdfund_signer_addr = get_crowdfund_signer_addr();

        // verify signer is the admin
        let admin_info = borrow_global<AdminInfo>(crowdfund_signer_addr);
        assert!(signer::address_of(admin) == admin_info.admin_address, ERROR_NOT_ADMIN);

        // assert that new fee cannot be greater than 5% or 500 (i.e. max cap)
        assert!(new_fee <= 500, ERROR_INVALID_NEW_FEE);

        // update the configuration
        let config = borrow_global_mut<Config>(crowdfund_signer_addr);
        config.min_funding_goal         = new_min_funding_goal;
        config.min_duration             = new_min_duration;
        config.min_contribution_amount  = new_min_contribution_amount;
        config.fee                      = new_fee;

    }

    // ---------------
    // General functions
    // ---------------

    // create new campaign
    public entry fun create_campaign(
        creator : &signer,
        name : String,
        description : String,
        image_url: String,
        funding_goal : u64,
        duration : u64,
        funding_type: u8
    ) : () acquires Config, CampaignRegistry, CreatorCampaigns {

        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let creator_address       = signer::address_of(creator);
        let config                = borrow_global<Config>(crowdfund_signer_addr);
        let campaign_registry     = borrow_global_mut<CampaignRegistry>(crowdfund_signer_addr);

        // check if creator has creator campaigns
        if (!exists<CreatorCampaigns>(creator_address)) {
            move_to(creator, CreatorCampaigns {
                campaigns: smart_table::new(),
            });
        };
        let creator_campaigns = borrow_global_mut<CreatorCampaigns>(creator_address);

        // verify min config requirements met
        assert!(funding_goal >= config.min_funding_goal, ERROR_MIN_FUNDING_GOAL_NOT_REACHED);
        assert!(duration >= config.min_duration, ERROR_MIN_DURATION_NOT_REACHED);

        // verify valid funding type
        assert!(funding_type == 0 || funding_type == 1, ERROR_INVALID_FUNDING_TYPE);

        // get next campaign id from registry
        let campaign_id                    = campaign_registry.next_campaign_id;
        campaign_registry.next_campaign_id = campaign_registry.next_campaign_id + 1;

        // set timestamps
        let current_time   = aptos_framework::timestamp::now_seconds();
        let end_timestamp  = current_time + duration;

        // create campaign
        let campaign = Campaign {
            creator : creator_address, 
            name, 
            description,
            image_url,
            funding_type, 
            fee : config.fee,

            funding_goal,
            contributed_amount : 0,
            claimed_amount : 0,
            leftover_amount : 0,
            refunded_amount : 0,

            duration,
            end_timestamp,
            contributors : smart_table::new<address, u64>(),

            claimed : false,
            is_successful : false
        };
        smart_table::add(&mut creator_campaigns.campaigns, campaign_id, campaign);
        
        // update campaign registry
        smart_table::add(&mut campaign_registry.campaign_to_creator, campaign_id, creator_address);

        // Emit CampaignCreatedEvent
        let event = CampaignCreatedEvent {
            campaign_id,
            creator : creator_address,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            end_timestamp,
            funding_type,
        };
        event::emit(event);
    }


    public entry fun update_campaign(
        creator: &signer,
        campaign_id: u64,
        name: String,
        description: String,
        image_url: String
    ) acquires CreatorCampaigns, CampaignRegistry {

        // init
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);

        // get creator address from registry
        let creator_address       = *smart_table::borrow(&campaign_registry.campaign_to_creator, campaign_id);
        
        // find campaign by id
        let creator_campaigns     = borrow_global_mut<CreatorCampaigns>(creator_address);
        let campaign              = smart_table::borrow_mut(&mut creator_campaigns.campaigns, campaign_id);

        // verify is creator
        assert!(signer::address_of(creator) == campaign.creator, ERROR_NOT_CAMPAIGN_CREATOR);

        // verify campaign is not past end timestamp
        let current_time = aptos_framework::timestamp::now_seconds();
        assert!(current_time <= campaign.end_timestamp, ERROR_CAMPAIGN_IS_OVER);

         // update the campaigns contributed and leftover amounts
        campaign.name           = name;
        campaign.description    = description;
        campaign.image_url      = image_url;

        // Emit CampaignUpdatedEvent
        let event = CampaignUpdatedEvent {
            campaign_id,
            name,
            description,
            image_url
        };
        event::emit(event);

    }


    public entry fun contribute<AptosCoin>(
        contributor : &signer,
        campaign_id : u64,
        amount : u64
    ) acquires Config, CreatorCampaigns, CampaignRegistry {

        // init
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let config                = borrow_global<Config>(crowdfund_signer_addr);
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);

        // get creator address from registry
        let creator_address       = *smart_table::borrow(&campaign_registry.campaign_to_creator, campaign_id);
        
        // find campaign by id
        let creator_campaigns     = borrow_global_mut<CreatorCampaigns>(creator_address);
        let campaign              = smart_table::borrow_mut(&mut creator_campaigns.campaigns, campaign_id);

        // verify campaign is not past end timestamp
        let current_time = aptos_framework::timestamp::now_seconds();
        assert!(current_time <= campaign.end_timestamp, ERROR_CAMPAIGN_IS_OVER);

        // verify min contribution amount reached
        assert!(amount >= config.min_contribution_amount, ERROR_MIN_CONTRIBUTION_AMOUNT_NOT_REACHED);

        // transfer Aptos tokens to the module
        aptos_account::transfer(contributor, crowdfund_signer_addr, amount);

        // add user's contribution
        let contributor_address = signer::address_of(contributor);
        if (smart_table::contains(&campaign.contributors, contributor_address)) {
            let existing_amount = smart_table::borrow_mut(&mut campaign.contributors, contributor_address);
            *existing_amount = *existing_amount + amount;
        } else {
            smart_table::add(&mut campaign.contributors, contributor_address, amount);
        };

         // update the campaigns contributed and leftover amounts
        campaign.contributed_amount = campaign.contributed_amount + amount;
        campaign.leftover_amount    = campaign.leftover_amount + amount;

        // Emit ContributionEvent
        let event = ContributionEvent {
            campaign_id,
            contributor: signer::address_of(contributor),
            amount,
        };
        event::emit(event);

    }


    public entry fun claim_funds(
        creator: &signer,
        campaign_id: u64
    ) acquires CreatorCampaigns, CampaignRegistry, CrowdfundSigner {

        // init
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let crowdfund_signer      = get_crowdfund_signer(crowdfund_signer_addr);
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);

        // get creator address from registry
        let creator_address       = *smart_table::borrow(&campaign_registry.campaign_to_creator, campaign_id);
        
        // find campaign by id
        let creator_campaigns     = borrow_global_mut<CreatorCampaigns>(creator_address);
        let campaign              = smart_table::borrow_mut(&mut creator_campaigns.campaigns, campaign_id);

        // verify the creator is the campaign creator
        assert!(signer::address_of(creator) == campaign.creator, ERROR_NOT_CAMPAIGN_CREATOR);

        // verify campaign has not been claimed already
        assert!(!campaign.claimed, ERROR_CAMPAIGN_FUNDS_ALREADY_CLAIMED);

        // get current time
        let current_time = aptos_framework::timestamp::now_seconds();

        if(campaign.funding_type == 0){
            
            // Keep-it-all Funding Type - creators can claim funds at any time
            
            // update total claimed amount to total contributed amount
            campaign.claimed_amount = campaign.contributed_amount;

            if(campaign.contributed_amount >= campaign.funding_goal){
                campaign.is_successful = true;
            };

            // calculate fees and claim total from campaign leftover amount to be claimed 
            let fee         = campaign.leftover_amount * campaign.fee / 10000;
            let claim_total = campaign.leftover_amount - fee;

            // transfer claim total to campaign creator
            coin::transfer<AptosCoin>(
                &crowdfund_signer,
                signer::address_of(creator),
                claim_total
            );

            // set leftover amount to zero now 
            campaign.leftover_amount = 0;

            if(current_time >= campaign.end_timestamp){
                campaign.claimed  = true;
            };

            // Emit ClaimFundsEvent
            let event = ClaimFundsEvent {
                campaign_id,
                claim_total,
            };
            event::emit(event);

        } else {
            
            // All-or-nothing Funding Type - creators can only claim funds if funding goal is met

            // verify campaign has ended
            assert!(current_time >= campaign.end_timestamp, ERROR_CAMPAIGN_IS_NOT_OVER);

            // verify funding goal is reached
            assert!(campaign.contributed_amount >= campaign.funding_goal, ERROR_CAMPAIGN_FUNDING_GOAL_NOT_REACHED);

            campaign.claimed_amount = campaign.contributed_amount - campaign.refunded_amount;

            // calculate fees and claim total
            let fee         = campaign.leftover_amount * campaign.fee / 10000;
            let claim_total = campaign.leftover_amount - fee;

            // transfer claim total to campaign creator
            coin::transfer<AptosCoin>(
                &crowdfund_signer,
                signer::address_of(creator),
                claim_total
            );

            campaign.leftover_amount    = 0;
            campaign.is_successful      = true;
            campaign.claimed            = true;

            // Emit ClaimFundsEvent
            let event = ClaimFundsEvent {
                campaign_id,
                claim_total,
            };
            event::emit(event);

        };
        
    }


    public entry fun refund(
        contributor: &signer,
        campaign_id: u64
    ) acquires CreatorCampaigns, CampaignRegistry, CrowdfundSigner {

        // init
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let crowdfund_signer      = get_crowdfund_signer(crowdfund_signer_addr);
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);

        // get creator address from registry
        let creator_address       = *smart_table::borrow(&campaign_registry.campaign_to_creator, campaign_id);
        
        // find campaign by id
        let creator_campaigns     = borrow_global_mut<CreatorCampaigns>(creator_address);
        let campaign              = smart_table::borrow_mut(&mut creator_campaigns.campaigns, campaign_id);

        // verify campaign funding type is ALL_OR_NOTHING (AON) - i.e. only AON funding type can be refunded
        assert!(campaign.funding_type == 1, ERROR_INVALID_FUNDING_TYPE);

        // verify campaign has ended 
        let current_time = aptos_framework::timestamp::now_seconds();
        assert!(current_time >= campaign.end_timestamp, ERROR_CAMPAIGN_IS_NOT_OVER);

        // verify campaign funds has not already been claimed
        assert!(!campaign.claimed, ERROR_CAMPAIGN_FUNDS_ALREADY_CLAIMED);

        // get user's contribution
        let contributor_address = signer::address_of(contributor);
        if (!smart_table::contains(&campaign.contributors, contributor_address)) {
            // Abort if the contributor is not found
            abort ERROR_CONTRIBUTOR_NOT_FOUND
        };

        let contribution_amount = smart_table::borrow_mut(&mut campaign.contributors, contributor_address);
        let refund_amount       = *contribution_amount;
        
        // verify refund_amount is greater than 0
        assert!(refund_amount > 0, ERROR_REFUND_AMOUNT_IS_ZERO); 

        // reset contribution amount to 0 to indicate a refund
        *contribution_amount = 0;
        
        campaign.leftover_amount = campaign.leftover_amount - refund_amount;
        campaign.refunded_amount = campaign.refunded_amount + refund_amount;

        // transfer refund amount to contributor
        coin::transfer<AptosCoin>(
            &crowdfund_signer,
            signer::address_of(contributor),
            refund_amount
        );

        // Emit RefundEvent
        let event = RefundEvent {
            campaign_id,
            contributor: signer::address_of(contributor),
            refund_amount,
        };
        event::emit(event);

    }

    // -----------------------------------
    // Views
    // -----------------------------------

    #[view]
    public fun get_campaign(campaign_id: u64): (
        address, String, String, String, u8, u64, u64, u64, u64, u64, u64, u64, u64, bool, bool
    ) acquires CreatorCampaigns, CampaignRegistry {
        
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);

        // get creator address from registry
        let creator_address       = *smart_table::borrow(&campaign_registry.campaign_to_creator, campaign_id);
        
        // find campaign by id
        let creator_campaigns     = borrow_global<CreatorCampaigns>(creator_address);
        let campaign_ref          = smart_table::borrow(&creator_campaigns.campaigns, campaign_id);

        // return the necessary fields from the campaign
        (
            campaign_ref.creator,
            campaign_ref.name,
            campaign_ref.description,
            campaign_ref.image_url,
            campaign_ref.funding_type,
            campaign_ref.fee,

            campaign_ref.funding_goal,
            campaign_ref.contributed_amount,
            campaign_ref.claimed_amount,
            campaign_ref.leftover_amount,
            campaign_ref.refunded_amount,

            campaign_ref.duration,
            campaign_ref.end_timestamp,
            
            campaign_ref.claimed,
            campaign_ref.is_successful
        )
    }

    #[view]
    public fun get_next_campaign_id(): (
        u64
    ) acquires CampaignRegistry {
        
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);
        
        campaign_registry.next_campaign_id
    }

    #[view]
    public fun get_contributor_amount(campaign_id: u64, contributor: address) : u64 acquires CreatorCampaigns, CampaignRegistry {
        
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let campaign_registry     = borrow_global<CampaignRegistry>(crowdfund_signer_addr);

        // get creator address from registry
        let creator_address       = *smart_table::borrow(&campaign_registry.campaign_to_creator, campaign_id);
        
        // find campaign by id
        let creator_campaigns     = borrow_global<CreatorCampaigns>(creator_address);
        let campaign_ref          = smart_table::borrow(&creator_campaigns.campaigns, campaign_id);

        // get the contribution amount for the specific contributor
        if (!smart_table::contains(&campaign_ref.contributors, contributor)) {
            abort ERROR_CONTRIBUTOR_NOT_FOUND
        };

        *smart_table::borrow(&campaign_ref.contributors, contributor)
    }

    #[view]
    public fun get_config(): (
        u64, u64, u64, u64
    ) acquires Config {

        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let config = borrow_global_mut<Config>(crowdfund_signer_addr);
                
        // return config values
        (
            config.min_funding_goal,
            config.min_duration,
            config.min_contribution_amount,
            config.fee
        )
    }


    // -----------------------------------
    // Helpers
    // -----------------------------------

    fun get_crowdfund_signer_addr(): address {
        object::create_object_address(&@crowdfund_addr, APP_OBJECT_SEED)
    }

    fun get_crowdfund_signer(crowdfund_signer_addr: address): signer acquires CrowdfundSigner {
        object::generate_signer_for_extending(&borrow_global<CrowdfundSigner>(crowdfund_signer_addr).extend_ref)
    }

    // -----------------------------------
    // Unit Tests
    // -----------------------------------

    #[test_only]
    use aptos_framework::timestamp;
    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use aptos_framework::aptos_coin::{Self};

    #[test_only]
    public fun setup_test(
        aptos_framework : &signer, 
        crowdfund : &signer,
        creator : &signer,
        contributor : &signer,
        contributorTwo : &signer,
        start_time : u64,
    ) : (address, address, address, address) acquires CrowdfundSigner {

        init_module(crowdfund);

        timestamp::set_time_has_started_for_testing(aptos_framework);

        // Set an initial time for testing
        timestamp::update_global_time_for_test(start_time);

        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);

        // crowdfund signer
        let crowdfund_signer_addr = get_crowdfund_signer_addr();
        let crowdfund_signer      = get_crowdfund_signer(crowdfund_signer_addr);

        // get addresses
        let crowdfund_addr       = signer::address_of(crowdfund);
        let creator_addr         = signer::address_of(creator);
        let contributor_addr     = signer::address_of(contributor);
        let contributor_two_addr = signer::address_of(contributorTwo);

        // create accounts
        account::create_account_for_test(crowdfund_signer_addr);
        account::create_account_for_test(crowdfund_addr);
        account::create_account_for_test(creator_addr);
        account::create_account_for_test(contributor_addr);
        account::create_account_for_test(contributor_two_addr);

        // register accounts
        coin::register<AptosCoin>(&crowdfund_signer);
        coin::register<AptosCoin>(crowdfund);
        coin::register<AptosCoin>(creator);
        coin::register<AptosCoin>(contributor);
        coin::register<AptosCoin>(contributorTwo);

        // mint some AptosCoin to the accounts
        let creator_coins           = coin::mint<AptosCoin>(100_000_000_000, &mint_cap);
        let contributor_coins       = coin::mint<AptosCoin>(100_000_000_000, &mint_cap);
        let contributor_two_coins   = coin::mint<AptosCoin>(100_000_000_000, &mint_cap);

        coin::deposit(creator_addr          , creator_coins);
        coin::deposit(contributor_addr      , contributor_coins);
        coin::deposit(contributor_two_addr  , contributor_two_coins);

        // Clean up capabilities
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);

        (crowdfund_addr, creator_addr, contributor_addr, contributor_two_addr)
    }


    #[view]
    #[test_only]
    public fun test_CampaignCreatedEvent(
        campaign_id : u64, 
        creator : address,
        name : String,
        description : String,
        image_url : String,
        funding_goal : u64,
        duration : u64,
        end_timestamp : u64,
        funding_type : u8
    ): CampaignCreatedEvent {
        let event = CampaignCreatedEvent{
            campaign_id,
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            end_timestamp,
            funding_type
        };
        return event
    }


    #[view]
    #[test_only]
    public fun test_CampaignUpdatedEvent(
        campaign_id : u64, 
        name : String,
        description : String,
        image_url : String,
    ): CampaignUpdatedEvent {
        let event = CampaignUpdatedEvent{
            campaign_id,
            name,
            description,
            image_url
        };
        return event
    }

    #[view]
    #[test_only]
    public fun test_ContributionEvent(
        campaign_id : u64, 
        contributor : address,
        amount : u64
    ): ContributionEvent {
        let event = ContributionEvent{
            campaign_id,
            contributor,
            amount
        };
        return event
    }

    #[view]
    #[test_only]
    public fun test_ClaimFundsEvent(
        campaign_id : u64, 
        claim_total : u64
    ): ClaimFundsEvent {
        let event = ClaimFundsEvent{
            campaign_id,
            claim_total
        };
        return event
    }

    #[view]
    #[test_only]
    public fun test_RefundEvent(
        campaign_id : u64, 
        contributor : address,
        refund_amount : u64
    ): RefundEvent {
        let event = RefundEvent{
            campaign_id,
            contributor,
            refund_amount
        };
        return event
    }

}