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


## Prerelease local testing of Node packages

You can use [verdaccio](https://verdaccio.org) as a local npm registry. Install it globally:

```
$ npm install -g verdaccio
```

For packages you want to test out, consider adding them to the config file explicitly and
disabling proxying to NPM. The config file is at `~/.config/verdaccio/config.yaml`. For elm-spec-runner
you would add:

```
packages:
  'elm-spec-core':
    access: $all
    publish: $all
    unpublish: $authenticated
    # proxy: npmjs

  'elm-spec-runner':
    access: $all
    publish: $all
    unpublish: $authenticated
    # proxy: npmjs
```

This will allow anyone to publish and will just use whatever is published to this registry.

Also, if trying to access verdaccio from inside a Docker container, it seems that adding this
line to the config helps:

```
listen: 0.0.0.0:4873
```

when you try to access verdaccio from inside the container at `http://host.docker.internal:4873`.

To publish to verdaccio:

1. Commit the code (no need to push, could be on a branch)
2. `npx lerna publish --canary --registry http://localhost:4873/`
- Publishes the latest code with a special tag indicating the latest commit to the verdaccio registry
3. To install: `npm install --save-dev elm-spec-runner@canary --registry http://localhost:4873/`


## Analyze ESBuild bundles

To analyze the esbuild bundle, first go to the `build.mjs` file and add `metafile: true`
as an option to the `build` function. Then change the command so you wait for the result
and write the metafile to a file like so:

```
const result = await esbuild.build({ ... })
fs.writeFileSync("meta.json", JSON.stringify(result.metafile))
```

Then you can use [Bundle Buddy](https://www.bundle-buddy.com) to view the results.