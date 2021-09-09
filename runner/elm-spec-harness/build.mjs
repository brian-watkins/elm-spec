import { NodeModulesPolyfillPlugin } from '@esbuild-plugins/node-modules-polyfill'
import esbuild from 'esbuild'

esbuild.build({
  entryPoints: [ "./entry.js" ],
  outfile: "./elmSpecHarness.js",
  bundle: true,
  minify: true,
  logLevel: 'info',
  plugins: [
    NodeModulesPolyfillPlugin()
  ],
})