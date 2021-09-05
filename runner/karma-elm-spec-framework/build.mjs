import { NodeModulesPolyfillPlugin } from '@esbuild-plugins/node-modules-polyfill'
import esbuild from 'esbuild'

esbuild.build({
  entryPoints: [ "./src/adapter_entry.js" ],
  outfile: "./lib/adapter.js",
  bundle: true,
  minify: true,
  logLevel: 'info',
  plugins: [
    NodeModulesPolyfillPlugin()
  ],
})