const path = require('path');

module.exports = {
    target: "webworker",
    entry: "./index.js",
    output: {
        filename: 'main.js',
        path: path.resolve(__dirname, 'dist'),
      },
    mode: "production",
   }
