const fs = require("fs");

async function main() {
  const MediaRights = await ethers.getContractFactory("MediaRights");
  const media = await MediaRights.deploy();
  await media.waitForDeployment();

  console.log(`Contract deployed to: ${media.target}`);

  fs.writeFileSync(
    "../blockchain-frontend/src/contracts/contract-address.json",
    JSON.stringify({ mediaRights: media.target }, null, 2)
  );

  console.log(
    `Contract address saved to 'blockchain-frontend/src/contracts/contract-address.json'`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
