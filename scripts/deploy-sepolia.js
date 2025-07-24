async function main() {
   const [deployer] = await ethers.getSigners();
   
   const MyNFT = await ethers.getContractFactory("MediaRights");

   const myNFT = await MyNFT.deploy(deployer.address); // Pass the deployer's address as the initial owner
   
   await myNFT.deployed();

   console.log("Contract Owner:", deployer.address);
   console.log("Contract deployed to address:", myNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
