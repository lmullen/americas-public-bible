const path = require('path');

module.exports = {
  mode: 'production',
  entry: {
    "verse-viewer": "./viz/verse-viewer/main.js",
  },
  output: {
    path: path.resolve(__dirname, 'assets/viz/'),
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          'style-loader',
          'css-loader',
        ],
      },
    ],
  },
  resolve: {
    modules: ['node_modules']
  }
};
