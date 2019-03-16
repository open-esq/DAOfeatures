# DAOfeatures
*Features that can be easily added to a DAOstack DAO.*

## DAOfeature
At its core, a DAOfeature is a scheme that inherits from the DAOfeature abstract contract. The DAOfeature contract consists of things like the UI management and a set of common view functions that can be used for analytics and displaying stuff in the UI, etc.).

## DAOfeatrue Extensions
Optional functionality like:
  - **Fee collection:** A DAOfeature owner can optionally collect fees for usage of a DAOfeature (microtransactions) - [FeeCollector.sol](https://github.com/dOrgTech/DAOfeatures/blob/master/features/tokenRegistry/contracts/FeeCollector.sol)

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

## DAOfeature Starter (a Truffle Box?)
A starter project with a small example for creating DAOfeatures. Might turn partly into an NPM package later.

Example use cases:
1. The DAOfeature Hub allows features to be added to any DAO (that has the  SchemeRegistrar scheme) and interacted with without adding anything to Alchemy etc.
2. Makes it easy to develop DAOfeatures
3. Makes it easy for developers to profit on their schemes
