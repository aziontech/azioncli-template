const path = require('path');
const webpack = require('webpack');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');

module.exports = {
    target: "webworker",
    entry: "./index.js",
    output: {
	      clean: true,
        filename: 'function.js',
        path: path.resolve(__dirname, 'worker'),
      },
    mode: "production",
    plugins: [
      new webpack.ProgressPlugin(),
      new CleanWebpackPlugin()
      ]
   };
