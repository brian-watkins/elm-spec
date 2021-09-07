import { NodeModulesPolyfillPlugin } from '@esbuild-plugins/node-modules-polyfill'
import esbuild from 'esbuild'

esbuild.build({
  entryPoints: [ "./src/index.js" ],
  outfile: "./dist/index.js",
  bundle: true,
  minify: true,
  logLevel: 'info',
  format: 'cjs',
  plugins: [
    NodeModulesPolyfillPlugin()
  ],
})