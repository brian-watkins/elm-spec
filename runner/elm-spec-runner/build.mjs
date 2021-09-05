import { NodeModulesPolyfillPlugin } from '@esbuild-plugins/node-modules-polyfill'
import esbuild from 'esbuild'

esbuild.build({
  entryPoints: [ "./adapterSrc/browserAdapter.js" ],
  outfile: "./src/browserAdapter.js",
  bundle: true,
  minify: true,
  logLevel: 'info',
  plugins: [
    NodeModulesPolyfillPlugin()
  ],
})