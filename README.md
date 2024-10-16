# AptosCrowd 

***A decentralised opensource crowdfunding platform for the Aptos community***

Designed for creators, developers, and indie makers alike, AptosCrowd is a decentralised crowdfunding platform that implements both the Flexible (Keep-It-All) and Fixed (All-Or-Nothing) crowdfunding models, as popularised by Indiegogo.

The most significant benefits of a decentralised crowdfunding platform are greater transparency and fee efficiency. With no intermediaries involved, it becomes easier to ensure that funds are spent appropriately and to track them if necessary.

Additionally, smart contracts eliminate traditional crowdfunding platform fees, such as the fundraiser fee (typically 5–8%) and the payment processor fee (around 2.9%).

In the Aptos ecosystem, a decentralised crowdfunding platform will also serve to foster a shared community spirit together in support of new and exciting projects for the future across various categories.

Through crowdfunding, project creators and developers can lower their risk and gauge the market or community's response to their project based on the amount of Aptos raised.

In contrast, the conventional approach entails either investing too much time or effort into a high-risk venture only to find lacklustre demand.

Over time and with a growing user base, we can adopt a decentralised governance model where members can shape the future direction of new initiatives and ventures.

With AptosCrowd, we hope to increase the number of successful projects on the Aptos blockchain driven by a supportive and growing community.

![AptosCrowd](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728732366/aptos-home-sc_gx1y5v.png)

## Crowdfunding Models on AptosCrowd

AptosCrowd is built upon the crowdfunding models outlined in Schwienbacher's (2000) research on Keep-It-All and All-Or-Nothing strategies.

By incorporating these foundational models, AptosCrowd offers project creators the flexibility to choose the approach that best aligns with their project's needs and goals.

 **Flexible (Keep-It-All - KIA) Model**:
  - **Funding Terms**: The project owner can claim funds at any time during the campaign, regardless of whether the funding goal is met.

  - **Supporter Terms**: Contributions are final with no refunds.

  - **Ideal For**: Small and scalable projects where any amount of funding can aid progress.

 **Fixed (All-Or-Nothing - AON) Model**:
  - **Funding Terms**: The project owner can only claim the funds if the target goal is reached by the campaign's end date.

  - **Supporter Terms**: Supporters can claim a refund if the project fails to meet its funding goal by the end date.

  - **Ideal For**: Large and non-scalable projects that require a minimum amount of funding to proceed.

![Crowdfunding models](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728731951/crowdfunding-models-sc_ondvky.png)

For both models, overfunding beyond the target amount is allowed, providing the potential for additional project enhancements. Campaigns should be set between 3 and 45 days, ensuring timely funding cycles.

AptosCrowd empowers project owners to choose the crowdfunding model that best aligns with their project's needs and goals.

Reference: [Schwienbacher, A. (2000). Crowdfunding Models: Keep-it-All vs. All-or-Nothing. SSRN Electronic Journal.](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2447567)

## Demo MVP

The AptosCrowd demo is accessible at [https://aptoscrowd.com](https://aptoscrowd.com) on the Aptos Testnet. The demo showcases sample crowdfunding campaigns using both the KIA and AON models.

**Features**:
- **Wallet Integration**: Users can connect their Aptos wallets to interact with the platform on the Aptos Testnet.

- **Sample Campaigns**: Explore sample campaigns with detailed descriptions, images, funding goals, and deadlines.

- **Create Campaigns**: Users are free to experiment and create campaigns of their own on the Aptos Testnet

- **Edit Campaigns**: Users can also edit campaigns they have created (only name, description, image)

- **Pledge Support**: Supporters can contribute and pledge Aptos tokens to campaigns directly through the platform.

- **Real-Time Updates**: Successful pledges trigger automatic campaign funding progress updates.

Our interactive demo provides a comprehensive preview of the AptosCrowd platform. Users can explore sample campaigns with detailed descriptions, images, funding goals, and deadlines to get a feel for how the live site will operate.

We also prioritise the user journey in both funding and supporting campaigns, making the process straightforward and accessible. For instance, we keep the campaign interface clean and minimalistic, featuring a main campaign image on the left side and a data panel on the right that displays real-time campaign information fetched directly from the blockchain storage. 

Once a contribution is successfully made and the transaction is recorded on the blockchain, the campaign's progress updates automatically to reflect the new funding status.

The frontend demo for AptosCrowd is maintained in a separate repository to ensure that the Move contracts remain focused and well-organised.

It can be found here: [AptosCrowd Frontend Github](https://github.com/0xblockbard/aptos-crowd-frontend)

Screenshot of sample campaigns:

![Sample Campaigns](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728731952/sample-campaigns-aptos-crowd_krt70a.png)


## Tech Overview and Considerations

We follow the Aptos Object Model approach, storing Campaign Objects on user accounts rather than on the crowdfunding contract to decentralise data storage, enhance scalability, and optimise gas costs. 

Each campaign creator has a CreatorCampaigns struct, containing a smart table mapping unique campaign IDs to Campaign structs. 

The crowdfund contract maintains a CampaignRegistry struct that maps campaign IDs to their respective creators. Campaign IDs are unique and sequentially assigned, ensuring that no two campaigns share the same ID, regardless of their creator.

Currently, there are no fees for creating campaigns, though this may be introduced in the future if required. Instead, a small fee may be collected as a percentage of the crowdfunded amount whenever a creator claims funds from a campaign. Also, updates to the crowdfund fee will only impact campaigns created after the change. 

This overall fee structure aims to support the ongoing growth and development of the AptosCrowd project, promoting long-term sustainability.

## Smart Contract Entrypoints

The AptosCrowd crowdfunding module includes five public entrypoints and one admin entrypoint:

**Public Entrypoints**
1. **create_campaign**: Initialises a new crowdfunding campaign.
   - **Input**: Creator's wallet address, crowdfunding model type (KIA or AON), campaign end date, name, description, image URL, and target amount.
   - **Output**: Updates blockchain state with campaign details.

2. **update_campaign**: Updates an existing crowdfunding campaign
   - **Input**: Creator's wallet address, campaign id, name, description, image URL
   - **Output**: Updates blockchain state with new campaign information.

3. **contribute**: Allows supporters to contribute and pledge Aptos to a campaign.
   - **Input**: Supporter's pledged amount in Aptos. Verifies the campaign's ongoing status and adds or updates the supporter’s contribution in the funders’ map.
   - **Output**: Updates campaign's contributed amount.

4. **claim_funds**: Enables the campaign creator to claim funds.
   - **Input**: Verifies that the campaign creator is the sender and checks the crowdfunding type.
   - **Output**: Claims funds if conditions are met, resetting the leftover amount to 0 for KIA campaigns.

5. **refund**: Allows supporters to get a refund for failed AON campaigns.
   - **Input**: Verifies that the sender is a supporter and that the campaign is AON type and has ended.
   - **Output**: Sends the refund amount to the supporter's wallet.

**Admin Entrypoints**

6. **update_config**: Allows the admin to update the crowdfund contract config (min_funding_goal, min_duration, min_contribution_amount, fee)

   - **Input**: Verifies that the signer is the admin and that a new fee cannot be greater than 5%
   - **Output**: Updates the crowdfund contract config 

## Code Coverage

AptosCrowd has comprehensive test coverage, with 100% of the codebase thoroughly tested. This includes a full range of scenarios that ensure the platform's reliability and robustness. 

The following section provides a breakdown of the tests that validate each function and feature, affirming that AptosCrowd performs as expected under all intended use cases.

![Code Coverage](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728727002/aptos-crowd-code-coverage-sc_z9elcc.png)

## Dummy Data Script

We have also included a dummy data script to populate the AptosCrowd Demo MVP with 9 sample crowdfunding campaigns. This helps to demonstrate our features and provides a realistic view of how campaigns appear and function on the site.

To run the dummy data script after deploying a local instance of our frontend and AptosCrowd Package, follow these steps:

```
# compile the dummy data script and get the script path location
aptos move compile-script

# copy the script path location and paste it at the end (replace path_to_script.mv)
aptos move run-script --compiled-script-path /path_to_script.mv
```

## Future Plans

Looking ahead, here are some plans to expand the features and capabilities of AptosCrowd in Phase 2.

### Planned Features:
- **DAO Governance**:  Implementing a Decentralised Autonomous Organization (DAO) to involve the community in decision-making processes, such as setting platform fees and initiating internally funded campaigns.

- **Enhanced Campaign Creation**: Enable more detailed descriptions with text and multimedia (images and videos) for campaigns to showcase their cause better.

- **User Profiles**: Introducing profiles where users can showcase the campaigns they've supported or created, along with features like comments and favourites to foster community engagement.

- **Advanced Search and Categories**: Adding tags, categories, and a robust search function to help users discover campaigns that align with their interests.

- **Pre- and Post-Crowdfunding Engagement**: Creating sections for campaign creators to gather feedback before launching and to provide updates after funding, building stronger relationships with supporters.

- **Integration with NFTs**: NFTs as rewards for early supporters or as part of campaign offerings.

### Long-Term Vision:
- **Community Growth**: Actively engage with the Aptos community to onboard new projects and supporters.

- **Continual Improvement**: Incorporate new features to maintain a competitive edge.

- **Educational Resources**: Provide guides and support for new users navigating decentralised crowdfunding.

By pursuing these plans, AptosCrowd aims to become a leading platform in the decentralised crowdfunding space, driving innovation and supporting a wide range of projects on Aptos.

## Conclusion

AptosCrowd presents a clean, user-friendly, and well-organised crowdfunding platform on the Aptos Blockchain, bringing together creators, developers, and the broader community to build projects on Aptos.

With our flexible crowdfunding models, low fees, and full transparency, we seek to empower project creators and supporters to unite, fostering a collaborative community that drives the growth and development of the Aptos ecosystem.

## Credits and Support

Thanks for reading till the end!

AptosCrowd is designed and built by 0xBlockBard, a solo indie maker passionate about building innovative products in the web3 space. 

With over 10 years of experience, my work spans full-stack and smart contract development, with the Laravel Framework as my go-to for web projects. I’m also familiar with Solidity, Rust, LIGO, and most recently, Aptos Move.

Beyond coding, I occasionally write and share insights on crypto market trends and interesting projects to watch. If you are interested to follow along my web3 journey, you can subscribe to my [Substack](https://www.0xblockbard.com/) here :)

Twitter / X: [0xBlockBard](https://x.com/0xblockbard)

Substack: [0xBlockBard Research](https://www.0xblockbard.com/)