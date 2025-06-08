async function main() {
  const MediaRights = await ethers.getContractFactory("MediaRights");
  const media = await MediaRights.deploy();
  await media.waitForDeployment();

  console.log(`Contract deployed to: ${media.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
