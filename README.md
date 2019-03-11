# DAOfeatures
Features that can be easily added to a DAOstack DAO.

In the future, it will be possible to browse a registry of DAOfeatures, where it will be a one-click operation to propose to add a feature to a DAO.

*A DAOfeature consists of a universal scheme (on chain) and a user interface (on IPFS) for interaction with that scheme.*

- **Fee collection:** A DAOfeature owner can optionally collect fees for usage of a DAOfeature (microtransactions) - [FeeCollector.sol](https://github.com/dOrgTech/DAOfeatures/blob/master/features/tokenRegistry/contracts/FeeCollector.sol)

- **User interface:** A DAOfuture owner can publish new versions of a DAOfeature UI. If a DAO wants to update to a new version of the UI, somebody has to propose the update, and it will be voted on - [UserInterface.sol](https://github.com/dOrgTech/DAOfeatures/blob/master/features/tokenRegistry/contracts/UserInterface.sol)
