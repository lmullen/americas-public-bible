const path = require('path');

module.exports = {
  mode: 'production',
  entry: {
    'verse-viewer': path.resolve(__dirname, 'viz/verse-viewer/main.js'),
  },
  output: {
    path: path.resolve(__dirname, 'assets/viz/'),
  },
  watchOptions: {
    aggregateTimeout: 300,
    poll: 1000,
    ignored: path.resolve(__dirname, 'node_modules'),
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },
};
