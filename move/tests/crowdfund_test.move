#[test_only]
module crowdfund_addr::crowdfund_test {

    use crowdfund_addr::crowdfund;
    
    use std::signer;
    use std::string::{String};

    use aptos_std::smart_table::{SmartTable};
    
    use aptos_framework::timestamp;
    use aptos_framework::object;
    use aptos_framework::event::{ was_event_emitted };

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
    const KEEP_IT_ALL_FUNDING_TYPE : u64            = 0;
    const ALL_OR_NOTHING_FUNDING_TYPE : u64         = 1;

    // Config defaults
    const DEFAULT_MIN_FUNDING_GOAL : u64            = 100_000_000; // 1 APT
    const DEFAULT_MIN_DURATION : u64                = 86400;       // 1 day
    const DEFAULT_MIN_CONTRIBUTION_AMOUNT : u64     = 10_000_000;  // 0.1 APT
    const DEFAULT_FEE : u64                         = 100;         // 1%

    // -----------------------------------
    // Structs
    // -----------------------------------

    /// Campaign Struct
    struct Campaign has key, store {
        
        creator : address, 
        name : String,
        description : String,
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
    struct Campaigns has key, store {
        campaigns : SmartTable<u64, Campaign>, 
        next_campaign_id : u64,
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
    // Test Constants
    // -----------------------------------

    const TEST_START_TIME : u64 = 1000000000;

    // -----------------------------------
    // Unit Tests
    // -----------------------------------

    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_MIN_FUNDING_GOAL_NOT_REACHED, location = crowdfund)]
    public entry fun test_create_campaign_should_fail_if_min_funding_goal_is_not_reached(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    )  {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 10_000_000; // should be at least 100_000_000 or 1 APT
        let duration        = 86400; 
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_MIN_DURATION_NOT_REACHED, location = crowdfund)]
    public entry fun test_create_campaign_should_fail_if_min_duration_is_not_reached(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86000;  // should be at least 86400 (1 day in seconds)
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_INVALID_FUNDING_TYPE, location = crowdfund)]
    public entry fun test_create_campaign_should_fail_if_funding_type_is_invalid(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400;  
        let funding_type    = 2; // should be 0 or 1

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_create_and_update_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        let creator_addr = signer::address_of(creator);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // get next campaign id
        let next_campaign_id = crowdfund::get_next_campaign_id();

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // verify next id is 0
        assert!(next_campaign_id == 0, 99);

        // get campaign from view
        let (
            creator_address, 
            campaign_name, 
            campaign_description, 
            campaign_image_url, 
            campaign_funding_type, 
            _campaign_fee, 
            campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            campaign_duration, 
            campaign_end_timestamp, 
            campaign_claimed, 
            campaign_is_successful
        ) = crowdfund::get_campaign(0);

        let end_timestamp = timestamp::now_seconds() + duration;
        
        // verify campaign was created correctly
        assert!(creator_address                 == creator_addr  , 100);
        assert!(campaign_name                   == name          , 101);
        assert!(campaign_description            == description   , 102);
        assert!(campaign_image_url              == image_url     , 103);
        assert!(campaign_funding_type           == funding_type  , 104);
        assert!(campaign_funding_goal           == funding_goal  , 105);

        assert!(campaign_contributed_amount     == 0             , 106);
        assert!(campaign_claimed_amount         == 0             , 107);
        assert!(campaign_leftover_amount        == 0             , 108);
        assert!(campaign_refunded_amount        == 0             , 109);

        assert!(campaign_duration               == duration      , 110);
        assert!(campaign_end_timestamp          == end_timestamp , 111);

        assert!(campaign_claimed                == false         , 112);
        assert!(campaign_is_successful          == false         , 113);

        // check event emits expected info
        let campaign_created_event = crowdfund::test_CampaignCreatedEvent(
            0,                  // campaign_id
            creator_address,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            end_timestamp,
            funding_type,
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&campaign_created_event), 114);

        // call update_campaign
        let new_name        = std::string::utf8(b"New Test Campaign Name");
        let new_description = std::string::utf8(b"New Test Campaign Description");
        let new_image_url   = std::string::utf8(b"New Test Campaign Image Url");
        crowdfund::update_campaign(
            creator,
            0,
            new_name,
            new_description,
            new_image_url
        );

        // check event emits expected info
        let campaign_updated_event = crowdfund::test_CampaignUpdatedEvent(
            0,                  // campaign_id
            new_name,
            new_description,
            new_image_url
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&campaign_updated_event), 115);
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_creator_can_create_multiple_campaigns(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // call create_campaign again
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // call create_campaign again
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_NOT_CAMPAIGN_CREATOR, location = crowdfund)]
    public entry fun test_non_creator_cannot_update_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // call update_campaign
        let new_name        = std::string::utf8(b"New Test Campaign Name");
        let new_description = std::string::utf8(b"New Test Campaign Description");
        let new_image_url   = std::string::utf8(b"New Test Campaign Image Url");
        crowdfund::update_campaign(
            contributor, // non-creator
            0,
            new_name,
            new_description,
            new_image_url
        );
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_IS_OVER, location = crowdfund)]
    public entry fun test_creator_cannot_update_campaign_after_it_is_no_longer_active(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // creator claim funds
        crowdfund::claim_funds(
            creator,
            0 // campaign id
        );

        // call update_campaign
        let new_name        = std::string::utf8(b"New Test Campaign Name");
        let new_description = std::string::utf8(b"New Test Campaign Description");
        let new_image_url   = std::string::utf8(b"New Test Campaign Image Url");
        crowdfund::update_campaign(
            creator,
            0,
            new_name,
            new_description,
            new_image_url
        );
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_user_can_contribute_to_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 50_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // create instance of expected event
        let contribution_event = crowdfund::test_ContributionEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&contribution_event), 100);

        // get contributor amount from view
        let (
            contribution_amount
        ) = crowdfund::get_contributor_amount(0, contributor_addr);

        // verify correct contribution amount
        assert!(amount == contribution_amount, 101);

        // get campaign from view
        let (
            _creator_address, 
            _campaign_name, 
            _campaign_description, 
            _campaign_image_url,
            _campaign_funding_type, 
            _campaign_fee, 
            _campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            _campaign_duration, 
            _campaign_end_timestamp, 
            _campaign_claimed, 
            _campaign_is_successful
        ) = crowdfund::get_campaign(0);

        // campaign values should be updated
        assert!(campaign_contributed_amount     == amount    , 102);
        assert!(campaign_claimed_amount         == 0         , 103);
        assert!(campaign_leftover_amount        == amount    , 104);
        assert!(campaign_refunded_amount        == 0         , 105);

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_user_can_contribute_to_campaign_again(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 30_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // create instance of expected event
        let contribution_event = crowdfund::test_ContributionEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&contribution_event), 100);

        // get contributor amount from view
        let (
            contribution_amount
        ) = crowdfund::get_contributor_amount(0, contributor_addr);

        // verify correct contribution amount
        assert!(amount == contribution_amount, 101);

        // call contribute again
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // create instance of expected event
        let contribution_event = crowdfund::test_ContributionEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&contribution_event), 100);

        // get contributor amount from view
        let (
            contribution_amount
        ) = crowdfund::get_contributor_amount(0, contributor_addr);

        // verify correct contribution amount
        assert!(amount * 2 == contribution_amount, 101);
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_multiple_users_can_contribute_to_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 50_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // create instance of expected event
        let contribution_event = crowdfund::test_ContributionEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&contribution_event), 100);

        // call contribute
        crowdfund::contribute(
            contributor_two,
            campaign_id,
            amount
        );

        // create instance of expected event
        let contribution_two_event = crowdfund::test_ContributionEvent(
            0,  // campaign_id
            contributor_two_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&contribution_two_event), 100);

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_MIN_CONTRIBUTION_AMOUNT_NOT_REACHED, location = crowdfund)]
    public entry fun test_user_should_not_be_able_to_contribute_less_than_min_contribution_amount(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 5_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure]
    public entry fun test_user_should_not_have_any_contribution_amount_if_he_has_not_contributed(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        let (
            _contribution_amount
        ) = crowdfund::get_contributor_amount(0, contributor_addr);
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure]
    public entry fun test_user_should_not_be_able_to_contribute_to_non_existent_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 2; // non-existent campaign
        let amount      = 5_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_IS_OVER, location = crowdfund)]
    public entry fun test_user_should_not_be_able_to_contribute_if_campaign_is_over(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; // 86400 seconds from now
        let funding_type    = 1;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 50_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_creator_should_be_able_to_claim_campaign_funds_anytime_for_KEEP_IT_ALL_Funding_Type(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 0; // KEEP IT ALL FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // creator can claim funds
        crowdfund::claim_funds(
            creator,
            0
        );

        // calculate fee
        let fee         = amount * DEFAULT_FEE / 10000;
        let claim_total = amount - fee;

        // create instance of expected event
        let claim_funds_event = crowdfund::test_ClaimFundsEvent(
            0,  // campaign_id
            claim_total
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&claim_funds_event), 100);
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_creator_should_be_able_to_claim_campaign_funds_for_KEEP_IT_ALL_Funding_Type_after_end_timestamp(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 0; // KEEP IT ALL FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        let end_timestamp = timestamp::now_seconds() + duration;
        timestamp::fast_forward_seconds(duration + 1);

        // creator can claim funds
        crowdfund::claim_funds(
            creator,
            0
        );

        // calculate fee
        let fee         = amount * DEFAULT_FEE / 10000;
        let claim_total = amount - fee;

        // create instance of expected event
        let claim_funds_event = crowdfund::test_ClaimFundsEvent(
            0,  // campaign_id
            claim_total
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&claim_funds_event), 100);

        // get campaign from view
        let (
            creator_address, 
            campaign_name, 
            campaign_description,
            campaign_image_url, 
            campaign_funding_type, 
            _campaign_fee, 
            campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            campaign_duration, 
            campaign_end_timestamp, 
            campaign_claimed, 
            campaign_is_successful
        ) = crowdfund::get_campaign(0);

        // verify campaign details are updated
        assert!(creator_address                 == creator_addr  , 100);
        assert!(campaign_name                   == name          , 101);
        assert!(campaign_description            == description   , 102);
        assert!(campaign_image_url              == image_url     , 103);
        assert!(campaign_funding_type           == funding_type  , 104);
        assert!(campaign_funding_goal           == funding_goal  , 105);

        assert!(campaign_contributed_amount     == amount                           , 106);
        assert!(campaign_claimed_amount         == campaign_contributed_amount      , 107);
        assert!(campaign_leftover_amount        == 0             , 108);
        assert!(campaign_refunded_amount        == 0             , 109);

        assert!(campaign_duration               == duration      , 110);
        assert!(campaign_end_timestamp          == end_timestamp , 111);

        assert!(campaign_claimed                == true          , 112);
        assert!(campaign_is_successful          == true          , 113);
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_creator_should_be_able_to_claim_campaign_funds_for_KEEP_IT_ALL_Funding_Type_multiple_times_after_user_contributions(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 0; // KEEP IT ALL FUNDING TYPE
        let end_timestamp   = timestamp::now_seconds() + duration;

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // creator can claim funds
        crowdfund::claim_funds(
            creator,
            0
        );

        // calculate fee
        let fee         = amount * DEFAULT_FEE / 10000;
        let claim_total = amount - fee;

        // create instance of expected event
        let claim_funds_event = crowdfund::test_ClaimFundsEvent(
            0,  // campaign_id
            claim_total
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&claim_funds_event), 100);

        // get campaign from view
        let (
            creator_address, 
            campaign_name, 
            campaign_description, 
            campaign_image_url, 
            campaign_funding_type, 
            _campaign_fee, 
            campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            campaign_duration, 
            campaign_end_timestamp, 
            campaign_claimed, 
            campaign_is_successful
        ) = crowdfund::get_campaign(0);

        // verify campaign details are updated
        assert!(creator_address                 == creator_addr   , 101);
        assert!(campaign_name                   == name           , 102);
        assert!(campaign_description            == description    , 103);
        assert!(campaign_image_url              == image_url      , 104);
        assert!(campaign_funding_type           == funding_type   , 105);
        assert!(campaign_funding_goal           == funding_goal   , 106);

        assert!(campaign_contributed_amount     == amount                           , 107);
        assert!(campaign_claimed_amount         == campaign_contributed_amount      , 108);
        assert!(campaign_leftover_amount        == 0              , 109);
        assert!(campaign_refunded_amount        == 0              , 110);

        assert!(campaign_duration               == duration       , 111);
        assert!(campaign_end_timestamp          == end_timestamp  , 112);

        assert!(campaign_claimed                == false          , 113);
        assert!(campaign_is_successful          == true           , 114);

        // Second contribution
        let amount_two = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor_two,
            campaign_id,
            amount
        );

        // creator can claim funds again
        crowdfund::claim_funds(
            creator,
            0
        );

        // calculate fee
        let fee         = amount_two * DEFAULT_FEE / 10000;
        let claim_total = amount_two - fee;

        // create instance of expected event
        let claim_funds_event = crowdfund::test_ClaimFundsEvent(
            0,  // campaign_id
            claim_total
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&claim_funds_event), 115);

        // get updated campaign from view
        let (
            _creator_address, 
            _campaign_name, 
            _campaign_description, 
            _campaign_image_url,
            _campaign_funding_type, 
            _campaign_fee, 
            _campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            _campaign_duration, 
            _campaign_end_timestamp, 
            _campaign_claimed, 
            _campaign_is_successful
        ) = crowdfund::get_campaign(0);

        assert!(campaign_contributed_amount     == amount + amount_two  , 116);
        assert!(campaign_claimed_amount         == amount + amount_two  , 117);
        assert!(campaign_leftover_amount        == 0                    , 118);
        assert!(campaign_refunded_amount        == 0                    , 119);

        // third contribution
        let amount_three = 50_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount_three
        );

        // creator can claim funds again
        crowdfund::claim_funds(
            creator,
            0
        );

        // calculate fee
        let fee         = amount_three * DEFAULT_FEE / 10000;
        let claim_total = amount_three - fee;

        // create instance of expected event
        let claim_funds_event = crowdfund::test_ClaimFundsEvent(
            0,  // campaign_id
            claim_total
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&claim_funds_event), 115);

        // get updated campaign from view
        let (
            _creator_address, 
            _campaign_name, 
            _campaign_description, 
            _campaign_image_url,
            _campaign_funding_type, 
            _campaign_fee, 
            _campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            _campaign_duration, 
            _campaign_end_timestamp, 
            _campaign_claimed, 
            _campaign_is_successful
        ) = crowdfund::get_campaign(0);

        assert!(campaign_contributed_amount     == amount + amount_two + amount_three , 120);
        assert!(campaign_claimed_amount         == amount + amount_two + amount_three , 121);
        assert!(campaign_leftover_amount        == 0                                  , 122);
        assert!(campaign_refunded_amount        == 0                                  , 123);

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_NOT_CAMPAIGN_CREATOR, location = crowdfund)]
    public entry fun test_non_creator_should_not_be_able_to_claim_campaign_funds(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 0; // KEEP IT ALL FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // contributor (non-creator) should not be able to claim funds
        crowdfund::claim_funds(
            contributor,
            0
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_IS_NOT_OVER, location = crowdfund)]
    public entry fun test_creator_should_not_be_able_to_claim_campaign_funds_anytime_for_ALL_OR_NOTHING_Funding_Type(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        crowdfund::claim_funds(
            creator,
            0
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_IS_NOT_OVER, location = crowdfund)]
    public entry fun test_creator_should_not_be_able_to_claim_campaign_funds_for_ALL_OR_NOTHING_Funding_Type_if_funding_goal_was_reached_but_campaign_is_not_over(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        crowdfund::claim_funds(
            creator,
            0
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_FUNDING_GOAL_NOT_REACHED, location = crowdfund)]
    public entry fun test_creator_should_not_be_able_to_claim_campaign_funds_for_ALL_OR_NOTHING_Funding_Type_if_funding_goal_was_not_reached(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 50_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        crowdfund::claim_funds(
            creator,
            0
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_FUNDS_ALREADY_CLAIMED, location = crowdfund)]
    public entry fun test_creator_should_not_be_able_to_claim_campaign_funds_for_ALL_OR_NOTHING_Funding_Type_more_than_once(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // first call to claim funds should work
        crowdfund::claim_funds(
            creator,
            0
        );

        // second call to claim funds should NOT work
        crowdfund::claim_funds(
            creator,
            0
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_creator_should_be_able_to_claim_funds_even_after_user_has_refunded(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 70_000_000;
        
        // call contribute (contributor one)
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        let amount_two  = 50_000_000;

        // call contribute (contributor two)
        crowdfund::contribute(
            contributor_two,
            campaign_id,
            amount_two
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // contributor one claims refund
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

        // create instance of expected event
        let refund_event = crowdfund::test_RefundEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&refund_event), 100);

        // get campaign from view
        let (
            _creator_address, 
            _campaign_name, 
            _campaign_description, 
            _campaign_image_url,
            _campaign_funding_type, 
            _campaign_fee, 
            _campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            _campaign_duration, 
            _campaign_end_timestamp, 
            _campaign_claimed, 
            _campaign_is_successful
        ) = crowdfund::get_campaign(0);

        // campaign values should be updated
        assert!(campaign_contributed_amount     == amount + amount_two  , 100);
        assert!(campaign_claimed_amount         == 0                    , 101);
        assert!(campaign_leftover_amount        == amount_two           , 102);
        assert!(campaign_refunded_amount        == amount               , 103);

        // creator can still claim funds as contributed amount was reached (not counting refunded amount)
        crowdfund::claim_funds(
            creator,
            0
        );

        // get campaign from view
        let (
            _creator_address, 
            _campaign_name, 
            _campaign_description, 
            _campaign_image_url,
            _campaign_funding_type, 
            _campaign_fee, 
            _campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            _campaign_duration, 
            _campaign_end_timestamp, 
            _campaign_claimed, 
            _campaign_is_successful
        ) = crowdfund::get_campaign(0);

        // campaign values should be updated
        assert!(campaign_contributed_amount     == amount + amount_two  , 104);
        assert!(campaign_claimed_amount         == amount_two           , 105);
        assert!(campaign_leftover_amount        == 0                    , 106);
        assert!(campaign_refunded_amount        == amount               , 107);

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_contributor_should_be_able_to_get_refund_of_contribution_for_ALL_OR_NOTHING_Funding_Type_after_end_timestamp_when_funding_goal_is_not_reached(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 70_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // contributor claim refund
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

        // create instance of expected event
        let refund_event = crowdfund::test_RefundEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&refund_event), 100);

        // get campaign from view
        let (
            _creator_address, 
            _campaign_name, 
            _campaign_description, 
            _campaign_image_url,
            _campaign_funding_type, 
            _campaign_fee, 
            _campaign_funding_goal, 
            campaign_contributed_amount, 
            campaign_claimed_amount, 
            campaign_leftover_amount, 
            campaign_refunded_amount, 
            _campaign_duration, 
            _campaign_end_timestamp, 
            _campaign_claimed, 
            _campaign_is_successful
        ) = crowdfund::get_campaign(0);

        assert!(campaign_contributed_amount     == amount        , 105);
        assert!(campaign_claimed_amount         == 0             , 106);
        assert!(campaign_leftover_amount        == 0             , 107);
        assert!(campaign_refunded_amount        == amount        , 108);

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_contributor_should_be_able_to_get_refund_of_contribution_for_ALL_OR_NOTHING_Funding_Type_after_end_timestamp_when_funding_goal_is_reached(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // contributor claim refund
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

        // create instance of expected event
        let refund_event = crowdfund::test_RefundEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&refund_event), 100);

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_REFUND_AMOUNT_IS_ZERO, location = crowdfund)]
    public entry fun test_contributor_should_not_be_able_to_call_refund_more_than_once(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // contributor claims refund
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

        // create instance of expected event
        let refund_event = crowdfund::test_RefundEvent(
            0,  // campaign_id
            contributor_addr,
            amount
        );

        // verify if expected event was emitted
        assert!(was_event_emitted(&refund_event), 100);

        // contributor should not be able to call refund again
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_IS_NOT_OVER, location = crowdfund)]
    public entry fun test_contributor_should_not_be_able_to_call_refund_if_campaign_is_not_over(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // contributor claims refund
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_INVALID_FUNDING_TYPE, location = crowdfund)]
    public entry fun test_contributor_should_not_be_able_to_call_refund_on_KEEP_IT_ALL_Funding_Type_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 0; // KEEP IT ALL FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // contributor claims refund
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CAMPAIGN_FUNDS_ALREADY_CLAIMED, location = crowdfund)]
    public entry fun test_contributor_should_not_be_able_to_call_refund_on_ALL_OR_NOTHING_Funding_Type_campaign_after_funds_have_already_been_claimed(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // creator claim funds
        crowdfund::claim_funds(
            creator,
            0 // campaign id
        );

        // contributor claims refund should fail
        crowdfund::refund(
            contributor,
            0 // campaign id
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_CONTRIBUTOR_NOT_FOUND, location = crowdfund)]
    public entry fun test_non_contributor_should_not_be_able_to_call_refund_on_ALL_OR_NOTHING_Funding_Type_campaign(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up initial values for creating a campaign
        let name            = std::string::utf8(b"Test Campaign");
        let description     = std::string::utf8(b"Test Description");
        let image_url       = std::string::utf8(b"Test Image Url");
        let funding_goal    = 100_000_000;
        let duration        = 86400; 
        let funding_type    = 1; // ALL OR NOTHING FUNDING TYPE

        // call create_campaign
        crowdfund::create_campaign(
            creator,
            name,
            description,
            image_url,
            funding_goal,
            duration,
            funding_type
        );

        // set up initial values for contributing to a campaign
        let campaign_id = 0;
        let amount      = 150_000_000;
        
        // call contribute
        crowdfund::contribute(
            contributor,
            campaign_id,
            amount
        );

        // fast forward to campaign over
        timestamp::fast_forward_seconds(duration + 1);

        // non-contributor claims refund should fail
        crowdfund::refund(
            contributor_two,
            0 // campaign id
        );

    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    public entry fun test_admin_should_be_able_to_update_config(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up new config values
        let new_min_funding_goal        = 200_000_000;
        let new_min_duration            = 50_000;
        let new_min_contribution_amount = 50_000_000;
        let new_fee                     = 200;

        // call update_config
        crowdfund::update_config(
            crowdfund,
            new_min_funding_goal,
            new_min_duration,
            new_min_contribution_amount,
            new_fee
        );

        let (
            min_funding_goal,
            min_duration,
            min_contribution_amount,
            fee 
        ) = crowdfund::get_config();

        assert!(min_funding_goal        == new_min_funding_goal         , 100);
        assert!(min_duration            == new_min_duration             , 101);
        assert!(min_contribution_amount == new_min_contribution_amount  , 102);
        assert!(fee                     == new_fee                      , 103);
        
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_NOT_ADMIN, location = crowdfund)]
    public entry fun test_non_admin_should_not_be_able_to_update_config(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up new config values
        let new_min_funding_goal        = 200_000_000;
        let new_min_duration            = 50_000;
        let new_min_contribution_amount = 50_000_000;
        let new_fee                     = 200;

        // call update_config
        crowdfund::update_config(
            creator,
            new_min_funding_goal,
            new_min_duration,
            new_min_contribution_amount,
            new_fee
        );
        
    }


    #[test(aptos_framework = @0x1, crowdfund=@crowdfund_addr, creator = @0x222, contributor = @0x333, contributor_two = @0x444)]
    #[expected_failure(abort_code = ERROR_INVALID_NEW_FEE, location = crowdfund)]
    public entry fun test_admin_should_not_be_able_to_set_fee_greater_than_10000(
        aptos_framework: &signer,
        crowdfund: &signer,
        creator: &signer,
        contributor: &signer,
        contributor_two: &signer,
    ) {

        // setup environment
        let (_crowdfund_addr, _creator_addr, _contributor_addr, _contributor_two_addr) = crowdfund::setup_test(aptos_framework, crowdfund, creator, contributor, contributor_two, TEST_START_TIME);

        // set up new config values
        let new_min_funding_goal        = 200_000_000;
        let new_min_duration            = 50_000;
        let new_min_contribution_amount = 50_000_000;
        let new_fee                     = 10001;

        // call update_config
        crowdfund::update_config(
            crowdfund,
            new_min_funding_goal,
            new_min_duration,
            new_min_contribution_amount,
            new_fee
        );
        
    }

}