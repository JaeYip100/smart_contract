async function main() {
  const MediaRights = await ethers.getContractFactory('MediaRights');
  const media = await MediaRights.deploy();
  await media.deployed();

  console.log(`Contract deployed to: ${media.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
