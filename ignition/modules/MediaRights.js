const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const MediaRightsModule = buildModule("MediaRightsModule", (m) => {
  const token = m.contract("MediaRights", [m.getAccount(0)]);

  return { token };
});

module.exports = MediaRightsModule;
