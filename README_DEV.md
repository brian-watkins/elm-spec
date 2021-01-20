## Developing elm-spec

This is a monorepo using [lerna](https://lerna.js.org) to manage multiple npm packages.


## Installing Dependencies

To install all dependencies:

```
$ npm install
$ npx lerna bootstrap
```

## Updating Dependencies

```
$ npx lernaupdate
```

and follow the prompts.

## Running Tests

```
$ npm test
```

## Publishing

1. fast-forward merge develop into master and push
2. `npx lerna version --no-private`
  - Choose versions for each package
  - Lerna will update the package.json appropriately for each package and push changes and push new release tags
  - The `no-private` flag means the `tests` module will not be versioned
3. `npx lerna publish from-git`
  - Publishes the latest tagged releases of the packages to npm
4. `npx elm bump`
  - Figures out the right semantic versioning for elm-spec and updates the elm.json; does not push to git
5. Commit and push
6. `git tag 1.1.0`
  - Where 1.1.0 is your new version
7. `git push --tags`
8. `npx elm publish`
9. Check out develop; rebase master; push.


