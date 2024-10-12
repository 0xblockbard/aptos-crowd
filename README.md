# AptosCrowd 

AptosCrowd is a decentralized crowdfunding platform that implements both the Flexible (Keep-It-All) and Fixed (All-Or-Nothing) crowdfunding models, as popularized by Indiegogo.

The most significant benefits of a decentralized crowdfunding platform are greater transparency and fee efficiency. With no intermediaries involved, it becomes easier to ensure that funds are spent appropriately and to track them if necessary.

Additionally, smart contracts eliminate traditional crowdfunding platform fees, such as the fundraiser fee (typically 5–8%) and the payment processor fee (around 2.9%).

In the Aptos ecosystem, a decentralized crowdfunding platform will also serve to foster a shared community spirit together in support of new and exciting projects for the future across various categories.

Through crowdfunding, project creators and developers can lower their risk and gauge the market or community's response to their project based on the amount of Aptos raised.

In contrast, the conventional approach entails either investing too much time or effort into a high-risk venture only to find lackluster demand.

Over time and with a growing user base, we can adopt a decentralized governance model where members can shape the future direction of new initiatives and ventures.

With AptosCrowd, we hope to increase the number of successful projects on the Aptos blockchain driven by a supportive and growing community.

## Crowdfunding Models on AptosCrowd

AptosCrowd is built upon the crowdfunding models outlined in Schwienbacher's (2000) research on Keep-It-All and All-Or-Nothing strategies.

By incorporating these foundational models, AptosCrowd offers project creators the flexibility to choose the approach that best aligns with their project's needs and goals.

![Crowdfunding models](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728731951/crowdfunding-models-sc_ondvky.png)

 **Flexible (Keep-It-All - KIA) Model**:
  - **Description**: The project owner can claim funds at any time during the campaign, regardless of whether the funding goal is met.

  - **Supporter Terms**: Contributions are final, and there will be no refunds.

  - **Ideal For**: Small and scalable projects where any amount of funding can aid progress.

 **Fixed (All-Or-Nothing - AON) Model**:
  - **Description**: The project owner can only claim the funds if the target goal is reached by the campaign's end date.

  - **Supporter Terms**: Supporters can claim a refund if the project fails to meet its funding goal by the end date.

  - **Ideal For**: Large and non-scalable projects that require a minimum amount of funding to proceed.

For both models, overfunding beyond the target amount is allowed, providing the potential for additional project enhancements. Campaigns should be set between 3 and 45 days, ensuring timely funding cycles.

AptosCrowd empowers project owners to choose the crowdfunding model that best aligns with their project's needs and goals.

Reference: [Schwienbacher, A. (2000). Crowdfunding Models: Keep-it-All vs. All-or-Nothing. SSRN Electronic Journal.](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2447567)

## Demo MVP

The AptosCrowd demo is accessible at [https://aptoscrowd.com](https://aptoscrowd.com) on the Aptos Testnet. The demo showcases sample crowdfunding campaigns using both the KIA and AON models.

**Features**:
- **Wallet Integration**: Users can connect their Aptos wallets to interact with the platform on the Aptos Testnet.

- **Sample Campaigns**: Explore sample campaigns with detailed descriptions, images, funding goals, and deadlines.

- **Create Campaigns**: Users are also free to experiment and create campaigns on their own

- **Edit Campaigns**: Users can also edit campaigns they have created on the Aptos Testnet (name, description, image)

- **Pledge Support**: Supporters can contribute and pledge Aptos tokens to campaigns directly through the platform.

- **Real-Time Updates**: Successful pledges trigger automatic updates to the campaigns's funding progress.

Our demo showcases how effortlessly blockchain technology can be integrated into crowdfunding platforms, emphasizing a seamless and user-friendly experience. 

We prioritize the user journey in both funding and supporting campaigns, making the process straightforward and accessible. 

The campaign interface is clean and minimalist, featuring a main campaign image on the left side and a data panel on the right that displays real-time campaign information fetched directly from smart contract storage. 

Once a contribution is successfully made and the transaction is recorded on the blockchain, the campaign's progress updates automatically to reflect the new funding status.

The frontend demo for AptosCrowd is maintained in a separate repository to ensure that the Move smart contracts remain focused and well-organized.

It can be found here: [AptosCrowd Frontend Github](https://github.com)

Screenshot of sample campaigns:

![Sample Campaigns](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728731952/sample-campaigns-aptos-crowd_krt70a.png)


## Tech Overview and Considerations

We adopt the Aptos Object Model, storing campaigns on user accounts to enhance scalability and optimize gas costs.

Each user has a CreatorCampaigns struct, which contains a smart table mapping from unique campaign IDs to Campaign structs. 

The crowdfund contract maintains a global CampaignRegistry struct that maps campaign IDs to their respective creators. Campaign IDs are unique and sequentially assigned, ensuring that no two campaigns share the same ID, regardless of their creator.

Currently, there are no fees for creating campaigns, though this may be introduced in the future if required. Instead, a small fee may be collected as a percentage of the crowdfunded amount whenever a creator claims funds from a campaign. 

Also, updates to the crowdfund fee will only impact campaigns created after the change. This overall fee structure aims to support the ongoing growth and development of the AptosCrowd project, promoting long-term sustainability.

## Smart Contract Entrypoints

The crowdfunding smart contract includes five public entrypoints and one admin entrypoint:

**Public Entrypoints**
1. **create_campaign**: Initializes a new crowdfunding campaign.
   - **Input**: Creator's wallet address, crowdfunding model type (KIA or AON), campaign end date, name, description, image URL, and target amount.
   - **Output**: Updates blockchain state with campaign details.

2. **update_campaign**: Updates an existing crowdfunding campaign information.
   - **Input**: Creator's wallet address, campaign id, name, description, image URL
   - **Output**: Updates blockchain state with new campaign information.

3. **contribute**: Allows supporters to contribute and pledge Aptos to a campaign.
   - **Input**: Supporter's pledged amount in Aptos. Verifies the campagin's ongoing status and adds or updates the supporter’s contribution in the funders’ map.
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

AptosCrowd has a 100% test coverage as shown below:

![Code Coverage](https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728727002/aptos-crowd-code-coverage-sc_z9elcc.png)


## Future Plans

Looking ahead, here are some plans to expand the features and capabilities of AptosCrowd in Phase 2.

### Planned Features:
- **DAO Governance**:  Implementing a Decentralized Autonomous Organization (DAO) to involve the community in decision-making processes, such as setting platform fees and initiating internally funded campaigns.

- **Enhanced Campaign Creation**: Enable more detailed descriptions with text and multimedia (images and videos) for campaigns to better showcase their cause.

- **User Profiles**: Introducing profiles where users can showcase the campaigns they've supported or created, along with features like comments and favourites to foster community engagement.

- **Advanced Search and Categories**: Adding tags, categories, and a robust search function to help users discover campaigns that align with their interests.

- **Pre- and Post-Crowdfunding Engagement**: Creating sections for campaign creators to gather feedback before launching and to provide updates after funding, building stronger relationships with supporters.

- **Integration of NFTs**: NFTs as rewards for early supporters or as part of campaign offerings.

### Long-Term Vision:
- **Community Growth**: Actively engage with the Aptos community to onboard new projects and supporters.

- **Continual Improvement**: Incorporate new features to maintain a competitive edge.

- **Educational Resources**: Provide guides and support for new users navigating decentralised crowdfunding.

By pursuing these plans, AptosCrowd aims to become a leading platform in the decentralized crowdfunding space, driving innovation and supporting a wide range of projects on Aptos.

## Conclusion

AptosCrowd presents a clean, user-friendly, and well-organized crowdfunding platform on the Aptos Blockchain, bringing together creators, developers, and the broader community to build projects on Aptos.

With our flexible crowdfunding models, low fees, and full transparency, we seek to empower project creators and supporters to unite, fostering a collaborative community that drives the growth and development of the Aptos ecosystem.