module.exports = {
  servers: {
    one: {
      host: 'comingle.csail.mit.edu',
      username: 'ubuntu',
      pem: "/afs/csail/u/e/edemaine/.ssh/private/id_rsa"
      // pem:
      // password:
      // or leave blank for authenticate from ssh-agent
    }
  },

  // Meteor server
  meteor: {
    name: 'comingle',
    path: '/afs/csail/u/e/edemaine/Projects/comingle',
    servers: {
      one: {}
    },
    docker: {
      image: 'abernix/meteord:node-12-base',
      stopAppDuringPrepareBundle: false
    },
    buildOptions: {
      serverOnly: true,
      buildLocation: '/scratch/comingle-build'
    },
    env: {
      ROOT_URL: 'https://comingle.csail.mit.edu',
      MAIL_URL: 'smtp://comingle.csail.mit.edu:25?ignoreTLS=true',
      //MAIL_FROM: 'comingle@comingle.csail.mit.edu',
      MONGO_URL: 'mongodb://mongodb/meteor',
      MONGO_OPLOG_URL: 'mongodb://mongodb/local',
      NODE_OPTIONS: '--trace-warnings'
    },
    deployCheckWaitTime: 200,
  },

  // Mongo server
  mongo: {
    oplog: true,
    port: 27017,
    servers: {
      one: {},
    },
  },

  // Reverse proxy for SSL
  proxy: {
    domains: 'comingle.csail.mit.edu',
    ssl: {
      letsEncryptEmail: 'edemaine@mit.edu',
      //crt: '../../comingle_csail_mit_edu.ssl/comingle_csail_mit_edu.pem',
      //key: '../../comingle_csail_mit_edu.ssl/comingle_csail_mit_edu.key',
      forceSSL: true,
    },
    clientUploadLimit: '0', // disable upload limit
    nginxServerConfig: '../.proxy.config',
  },

  // Run 'npm install' before deploying, to ensure packages are up-to-date
  hooks: {
    'pre.deploy': {
      localCommand: 'npm install'
    }
  },
};
