const path = require('path')
const esbuild = require('esbuild')
const { NodeModulesPolyfillPlugin } = require('@esbuild-plugins/node-modules-polyfill')

exports.bundleRunnerCode = async () => {
  const result = await esbuild.build({
    entryPoints: [ path.join(__dirname, "specRunner.js") ],
    bundle: true,
    write: false,
    outdir: 'out',
    define: { global: 'window' },
    plugins: [
      NodeModulesPolyfillPlugin()
    ]
  })

  const out = result.outputFiles[0]

  return Buffer.from(out.contents).toString('utf-8')
}