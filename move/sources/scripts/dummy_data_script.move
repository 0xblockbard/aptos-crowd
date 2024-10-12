script {
    use std::string;
    use std::vector;
    // use aptos_framework::signer;
    use crowdfund_addr::crowdfund;

    fun setup_dummy_data(creator: &signer) {
        let name_bytes_list = vector[
            b"ChainEdu: Decentralized Learning Platform",
            b"MetaHealth: Blockchain-Based Health Records",
            b"SolarNode: Peer-to-Peer Renewable Energy Trading",
            b"FitChain: Fitness Tracking with Rewards",
            b"TravelBlock: Blockchain-Powered Travel Booking",
            b"GameFi Arena: Decentralized Game Development Fund",
            b"MusicChain: Decentralized Music Royalties Platform",
            b"FoodChain: Farm-to-Table Blockchain Solution",
            b"CryptoClinic: Decentralized Healthcare Network",
        ];

        let description_bytes_list = vector[
            b"ChainEdu is a decentralized education platform that leverages blockchain to offer transparent, tamper-proof learning credentials. Students can earn NFTs as certificates and degrees, ensuring lifelong verification and accessibility.",
            b"MetaHealth is a decentralized platform that enables users to securely store and share their health records on the blockchain. Patients have full control over their data, which can be accessed only with their permission by healthcare providers.",
            b"SolarNode allows homeowners and businesses with solar panels to sell excess energy to neighbors via blockchain, creating a decentralized green energy market. Participants can buy clean energy directly from peers, reducing reliance on traditional grids.",
            b"FitChain is a fitness app that leverages blockchain to track users' activity and offers token-based rewards for meeting fitness goals. Users can redeem tokens for workout gear, supplements, or donate them to health-related causes.",
            b"TravelBlock is a decentralized platform for booking flights, hotels, and car rentals using cryptocurrency. By eliminating intermediaries, the platform ensures cheaper prices and seamless payment options for travelers around the world.",
            b"GameFi Arena is a blockchain-based funding platform for indie game developers. It allows developers to raise funds for game projects, offering early access and in-game NFTs to supporters.",
            b"MusicChain allows musicians to tokenize their royalties and raise funds directly from fans. Fans can buy royalty shares as NFTs, earning a portion of the artist's future income, while musicians receive upfront capital for their projects.",
            b"FoodChain is a decentralized platform connecting farmers directly with consumers. Blockchain ensures full transparency in the food supply chain, allowing consumers to track the journey of their food from farm to table.",
            b"CryptoClinic provides blockchain-based healthcare services, allowing users to pay for medical consultations, treatments, and insurance with cryptocurrency. The platform ensures privacy and transparency, with blockchain-enabled medical record access."
        ];

        let image_url_bytes_list = vector[
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1727952345/chain-edu.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1727953558/metahealth.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1727953715/solarnode.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728205071/fitchain.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728204571/travelblock-2.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728204379/gamefi-arena-2.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728203889/musicchain.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728203686/foodchain.png",
            b"https://res.cloudinary.com/blockbard/image/upload/c_scale,w_auto,q_auto,f_auto,fl_lossy/v1728204664/crypto-clinic.png",
        ];

        let funding_goal_list = vector[
            1_00_000_000, // 1 APT
            5_00_000_000, // 5 APT
            2_00_000_000, // 2 APT
            3_00_000_000, // 3 APT
            4_00_000_000, // 4 APT
            6_00_000_000, // 6 APT
            4_00_000_000, // 4 APT
            3_00_000_000, // 3 APT
            5_00_000_000, // 5 APT
        ];

        let duration_list = vector[
            604800,   // 7 days
            1209600,  // 14 days
            2592000,  // 30 days
            1209600,  // 14 days
            1209600,  // 14 days
            1209600,  // 14 days
            1209600,  // 14 days
            1209600,  // 14 days
            1209600,  // 14 days
        ];

        let funding_type_list = vector[
            0, // keep it all
            1, // all or nothing
            0,
            0,
            1,
            0,
            1,
            0,
            1
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
