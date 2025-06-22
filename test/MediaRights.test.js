const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MediaRights", function () {
  let MediaRights;
  let mediaRights;
  let owner;
  let creator;
  let buyer;
  let recipient;

  const METADATA_URI = "https://example.com/metadata/1";
  const ROYALTY_FEE = ethers.parseEther("0.1"); // 0.1 ETH

  beforeEach(async function () {
    // Get signers
    [owner, creator, buyer, recipient] = await ethers.getSigners();

    // Deploy contract
    MediaRights = await ethers.getContractFactory("MediaRights");
    mediaRights = await MediaRights.deploy(owner.address);
    await mediaRights.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await mediaRights.owner()).to.equal(owner.address);
    });

    it("Should set the correct name and symbol", async function () {
      expect(await mediaRights.name()).to.equal("MediaRights");
      expect(await mediaRights.symbol()).to.equal("MNFT");
    });

    it("Should start with tokenCount at 0", async function () {
      expect(await mediaRights.tokenCount()).to.equal(0);
    });
  });

  describe("Minting NFTs", function () {
    it("Should mint a new NFT with correct details", async function () {
      const tx = await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        ROYALTY_FEE
      );

      // Check token was minted
      expect(await mediaRights.ownerOf(0)).to.equal(recipient.address);
      expect(await mediaRights.tokenURI(0)).to.equal(METADATA_URI);
      expect(await mediaRights.tokenCount()).to.equal(1);

      // Check media data
      const mediaData = await mediaRights.mediaData(0);
      expect(mediaData.royaltyFee).to.equal(ROYALTY_FEE);
      expect(mediaData.creator).to.equal(creator.address);

      // Check event was emitted
      await expect(tx)
        .to.emit(mediaRights, "MediaMinted")
        .withArgs(0, creator.address, METADATA_URI, ROYALTY_FEE);
    });

    it("Should increment tokenCount correctly", async function () {
      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        ROYALTY_FEE
      );
      expect(await mediaRights.tokenCount()).to.equal(1);

      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        "https://example.com/metadata/2",
        ROYALTY_FEE
      );
      expect(await mediaRights.tokenCount()).to.equal(2);
    });

    it("Should allow different creators to mint", async function () {
      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        ROYALTY_FEE
      );

      await mediaRights.connect(buyer).mintNFT(
        recipient.address,
        "https://example.com/metadata/2",
        ethers.parseEther("0.2")
      );

      const mediaData0 = await mediaRights.mediaData(0);
      const mediaData1 = await mediaRights.mediaData(1);

      expect(mediaData0.creator).to.equal(creator.address);
      expect(mediaData1.creator).to.equal(buyer.address);
    });
  });

  describe("Accessing Media", function () {
    beforeEach(async function () {
      // Mint an NFT for testing
      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        ROYALTY_FEE
      );
    });

    it("Should allow access with sufficient payment", async function () {
      const initialCreatorBalance = await ethers.provider.getBalance(creator.address);

      const tx = await mediaRights.connect(buyer).accessMedia(0, {
        value: ROYALTY_FEE
      });

      // Check creator received payment
      const finalCreatorBalance = await ethers.provider.getBalance(creator.address);
      expect(finalCreatorBalance - initialCreatorBalance).to.equal(ROYALTY_FEE);

      // Check event was emitted
      await expect(tx)
        .to.emit(mediaRights, "MediaAccessed")
        .withArgs(0, buyer.address, ROYALTY_FEE);

      // Check return value (this is tricky to test directly, but we can call it as a view function)
      const result = await mediaRights.connect(buyer).accessMedia.staticCall(0, {
        value: ROYALTY_FEE
      });
      expect(result).to.equal(METADATA_URI);
    });

    it("Should allow access with overpayment", async function () {
      const overpayment = ethers.parseEther("0.2");
      const initialCreatorBalance = await ethers.provider.getBalance(creator.address);

      await mediaRights.connect(buyer).accessMedia(0, {
        value: overpayment
      });

      const finalCreatorBalance = await ethers.provider.getBalance(creator.address);
      expect(finalCreatorBalance - initialCreatorBalance).to.equal(overpayment);
    });

    it("Should reject access with insufficient payment", async function () {
      const insufficientPayment = ethers.parseEther("0.05");

      await expect(
        mediaRights.connect(buyer).accessMedia(0, {
          value: insufficientPayment
        })
      ).to.be.revertedWith("Insufficient payment");
    });

    it("Should reject access for non-existent token", async function () {
      await expect(
        mediaRights.connect(buyer).accessMedia(999, {
          value: ROYALTY_FEE
        })
      ).to.be.revertedWith("NFT does not exist");
    });
  });

  describe("Getter Functions", function () {
    beforeEach(async function () {
      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        ROYALTY_FEE
      );
    });

    it("Should return correct royalty fee", async function () {
      expect(await mediaRights.getRoyaltyFee(0)).to.equal(ROYALTY_FEE);
    });

    it("Should return correct creator", async function () {
      expect(await mediaRights.getCreator(0)).to.equal(creator.address);
    });

    it("Should revert for non-existent token in getRoyaltyFee", async function () {
      await expect(mediaRights.getRoyaltyFee(999))
        .to.be.revertedWith("NFT does not exist");
    });

    it("Should revert for non-existent token in getCreator", async function () {
      await expect(mediaRights.getCreator(999))
        .to.be.revertedWith("NFT does not exist");
    });
  });

  describe("ERC721 Functionality", function () {
    beforeEach(async function () {
      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        ROYALTY_FEE
      );
    });

    it("Should support ERC721 transfers", async function () {
      // Transfer from recipient to buyer
      await mediaRights.connect(recipient).transferFrom(
        recipient.address,
        buyer.address,
        0
      );

      expect(await mediaRights.ownerOf(0)).to.equal(buyer.address);
    });

    it("Should maintain creator data after transfer", async function () {
      // Transfer ownership
      await mediaRights.connect(recipient).transferFrom(
        recipient.address,
        buyer.address,
        0
      );

      // Creator should remain the same
      expect(await mediaRights.getCreator(0)).to.equal(creator.address);
      expect(await mediaRights.getRoyaltyFee(0)).to.equal(ROYALTY_FEE);
    });

    it("Should still pay royalties to original creator after transfer", async function () {
      // Transfer ownership
      await mediaRights.connect(recipient).transferFrom(
        recipient.address,
        buyer.address,
        0
      );

      const initialCreatorBalance = await ethers.provider.getBalance(creator.address);

      // New owner or someone else accessing should still pay original creator
      await mediaRights.connect(owner).accessMedia(0, {
        value: ROYALTY_FEE
      });

      const finalCreatorBalance = await ethers.provider.getBalance(creator.address);
      expect(finalCreatorBalance - initialCreatorBalance).to.equal(ROYALTY_FEE);
    });
  });

  describe("Edge Cases", function () {
    it("Should handle zero royalty fee", async function () {
      await mediaRights.connect(creator).mintNFT(
        recipient.address,
        METADATA_URI,
        0
      );

      // Should allow access with no payment
      await expect(
        mediaRights.connect(buyer).accessMedia(0, { value: 0 })
      ).to.not.be.reverted;
    });

    it("Should handle multiple NFTs with different royalty fees", async function () {
      const fee1 = ethers.parseEther("0.1");
      const fee2 = ethers.parseEther("0.2");

      await mediaRights.connect(creator).mintNFT(recipient.address, METADATA_URI, fee1);
      await mediaRights.connect(creator).mintNFT(recipient.address, "uri2", fee2);

      expect(await mediaRights.getRoyaltyFee(0)).to.equal(fee1);
      expect(await mediaRights.getRoyaltyFee(1)).to.equal(fee2);

      // Should require correct payment for each
      await expect(
        mediaRights.connect(buyer).accessMedia(1, { value: fee1 })
      ).to.be.revertedWith("Insufficient payment");

      await expect(
        mediaRights.connect(buyer).accessMedia(1, { value: fee2 })
      ).to.not.be.reverted;
    });
  });
});