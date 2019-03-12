# DAOfeatures
Features that can be easily added to a DAOstack DAO.

*A DAOfeature consists of a universal scheme (on chain) and a user interface (on IPFS) for interaction with that scheme.*

## DAOfeature Lib (EthPm) consists of: 
- Core DAOfeature contract to enherite from when creating DAOfeatures (some common functionality used by the DAOfeatureRegistry ++)
- Optional functionality like:
  - **Fee collection:** A DAOfeature owner can optionally collect fees for usage of a DAOfeature (microtransactions) - [FeeCollector.sol](https://github.com/dOrgTech/DAOfeatures/blob/master/features/tokenRegistry/contracts/FeeCollector.sol)
  - **User interface:** A DAOfuture owner can publish new versions of a DAOfeature UI. If a DAO wants to update to a new version of the UI, somebody has to propose the update, and it will be voted on - [UserInterface.sol](https://github.com/dOrgTech/DAOfeatures/blob/master/features/tokenRegistry/contracts/UserInterface.sol)

## DAOfeature Hub 
Functionality:
- Browse DAOfeatures, read about them, see the number of users, check out the UI, etc.
- Add a feature to a DAO:
  1. Fill in the DAO's avatar address
  2. Click propose to add this feature (this will work for every DAO that implements the SchemeRegistrar scheme)
- See and interact with all features that are added to a DAO
  1. Fill in a DAO's avatar address
  2. All DAOfeatures that are registered for that DAO will be listed. Click one of the features to open the UI for that feature.
  3. Interact with the UI (for instance proposing something for the DAO to do).

## DAOfeature Starter
A starter project with a small example for creating DAOfeatures. Might turn partly into an NPM package later.

Example use cases:
1. The DAOfeature Hub allows features to be added to any DAO (that has the  SchemeRegistrar scheme) and interacted with without adding anything to Alchemy etc.
2. Makes it easy to develop DAOfeatures
3. Makes it easy for developers to profit on their schemes
