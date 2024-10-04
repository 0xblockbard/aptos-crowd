script {
    use std::string;
    use std::vector;
    // use aptos_framework::signer;
    use crowdfund_addr::crowdfund;

    fun setup_dummy_data(creator: &signer) {
        let name_bytes_list = vector[
            b"ChainEdu: Decentralized Learning Platform",
            b"MetaHealth: Blockchain-Based Health Records",
            b"SolarNode: Peer-to-Peer Renewable Energy Trading"
        ];

        let description_bytes_list = vector[
            b"ChainEdu is a decentralized education platform that leverages blockchain to offer transparent, tamper-proof learning credentials. Students can earn NFTs as certificates and degrees, ensuring lifelong verification and accessibility.",
            b"MetaHealth is a decentralized platform that enables users to securely store and share their health records on the blockchain. Patients have full control over their data, which can be accessed only with their permission by healthcare providers.",
            b"SolarNode allows homeowners and businesses with solar panels to sell excess energy to neighbors via blockchain, creating a decentralized green energy market. Participants can buy clean energy directly from peers, reducing reliance on traditional grids."
        ];

        let image_url_bytes_list = vector[
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1727952345/chain-edu.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1727953558/metahealth.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1727953715/solarnode.png"
        ];

        let funding_goal_list = vector[
            10_00_000_000, // 10 APT
            50_00_000_000, // 50 APT
            20_00_000_000  // 20 APT
        ];

        let duration_list = vector[
            604800,   // 7 days
            1209600,  // 14 days
            2592000   // 30 days
        ];

        let funding_type_list = vector[
            0, // keep it all
            1, // all or nothing
            0
        ];

        let i = 0;
        let len = vector::length(&name_bytes_list);
        while (i < len) {
            let name_bytes = *vector::borrow(&name_bytes_list, i);
            let description_bytes = *vector::borrow(&description_bytes_list, i);
            let image_url_bytes = *vector::borrow(&image_url_bytes_list, i);
            let funding_goal = *vector::borrow(&funding_goal_list, i);
            let duration = *vector::borrow(&duration_list, i);
            let funding_type = *vector::borrow(&funding_type_list, i);

            let name = string::utf8(name_bytes);
            let description = string::utf8(description_bytes);
            let image_url = string::utf8(image_url_bytes);

            crowdfund::create_campaign(
                creator,
                name,
                description,
                image_url,
                funding_goal,
                duration,
                funding_type
            );
            i = i + 1;
        }
    }
}
