// Karma configuration
// Generated on Thu Oct 31 2019 20:38:28 GMT-0400 (Eastern Daylight Time)

module.exports = function(config) {
  config.set({

    // base path that will be used to resolve all patterns (eg. files, exclude)
    basePath: 'sample',

    plugins: [
      require.resolve('./'),
      'karma-chrome-launcher'
    ],

    // frameworks to use
    // available frameworks: https://npmjs.org/browse/keyword/karma-adapter
    frameworks: ['elm-spec'],

    elmSpec: {
      cwd: './sample',
      specs: './specs/**/*Spec.elm'
    },

    client: {
      elmSpec: {
        tags: [ 'fun' ],
        endOnFailure: true
      }
    },

    // list of files / patterns to load in the browser
    files: [
      { pattern: 'src/*.elm', included: false, served: false },
      { pattern: 'specs/**/*Spec.elm', included: false, served: false }
    ],


    // list of files / patterns to exclude
    exclude: [
    ],


    // preprocess matching files before serving them to the browser
    // available preprocessors: https://npmjs.org/browse/keyword/karma-preprocessor
    preprocessors: {
      "src/*.elm": [ "elm-spec" ],
      "specs/**/*Spec.elm": [ "elm-spec" ]
    },

    // test results reporter to use
    // possible values: 'dots', 'progress'
    // available reporters: https://npmjs.org/browse/keyword/karma-reporter
    reporters: ['elm-spec'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // start these browsers
    // available browser launchers: https://npmjs.org/browse/keyword/karma-launcher
    browsers: ['MyChrome'],
    // browsers: ['MyChromeHeadless'],

    customLaunchers: {
      MyChrome: {
        base: 'Chrome',
        flags: [
          '--disable-backgrounding-occluded-windows', // necessary to run tests when browser is not visible
        ]
      }
    //   MyChromeHeadless: {
    //     base: 'ChromeHeadless',
    //     flags: ['--no-sandbox']
    //   }
    },


    // Continuous Integration mode
    // if true, Karma captures browsers, runs the tests and exits
    singleRun: false,

    // Concurrency level
    // how many browser should be started simultaneous
    concurrency: Infinity
  })
}
