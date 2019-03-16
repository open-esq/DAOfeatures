# DAOfeatures
*Features that can be easily added to a DAOstack DAO.*

## DAOfeature
*A DAOfeature is a scheme that inherits from the DAOfeature abstract contract.* 

The DAOfeature contract consists of things like [UI management](https://github.com/dOrgTech/DAOfeatures/blob/master/features/registrars/contracts/UserInterface.sol) and a set of common view functions that can be used for analytics, discoverability and displaying stuff in the UI, etc.).

## DAOfeatrue Extensions
*Common optional functionality that can be easily added to a DAOfeature.*

Optional functionality like:
  - **Fee collection:** A DAOfeature owner can optionally collect fees for usage of a DAOfeature (microtransactions) - [FeeCollector.sol](https://github.com/dOrgTech/DAOfeatures/blob/master/features/registrars/contracts/FeeCollector.sol)

## DAOfeature Hub
*A hub for discovering and interacting with DAOfeatures.*

Functionality:
- Browse DAOfeatures, read about them, see the number of users, check out the UI, etc.
- Add a feature to a DAO:
  1. Fill in the DAO's avatar address
  2. Click propose to add this feature (this will work for every DAO that implements the SchemeRegistrar scheme)
- See and interact with all features that are added to a DAO
  1. Fill in a DAO's avatar address
  2. All DAOfeatures that are registered for that DAO will be listed. Click one of the features to open the UI for that feature.
  3. Interact with the UI (for instance proposing something for the DAO to do).

## DAOfeature Starter (a Truffle Box?)
*A starter project with a small example for creating DAOfeatures and tools for deploying and managing the UI.*

This would make it easy to implement a DAOfeature (including testing, deployment etc.). And it would also make it easy to develop the UI and to publish new versions of the UI (push the new UI to IPFS and push the address of the new UI to the DAOfeature UI manager).

Example use cases:
1. The DAOfeature Hub allows features to be added to any DAO (that has the  SchemeRegistrar scheme) and interacted with without adding anything to Alchemy etc.
2. Makes it easy to develop DAOfeatures
3. Makes it easy for developers to profit on their schemes
