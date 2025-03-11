<!--monopod:start-->
# node22
| | |
| - | - |
| **OCI Reference** | `ghcr.io/the-mines/sbi/node22` |


* [View Image in the GitHub Container Registry](https://github.com/The-Mines/sbi/pkgs/container/sbi%2Fnode22)
* [View the Repository](https://github.com/The-Mines/sbi) for a full list of available images.
* [Report Issues](https://github.com/The-Mines/sbi/issues) for support and feature requests.

---
<!--monopod:end-->

<!--overview:start-->
# Spellcarver Base Image for Node.js 22 LTS

Minimal container image for running Node.js 22 LTS applications

Spellcarver Base Images (SBI) are regularly-updated, minimal container images with low-to-zero CVEs.
<!--overview:end-->

<!--getting:start-->
## Download this Image
This image is available on GitHub Container Registry:

```
# Base image
docker pull ghcr.io/the-mines/sbi/node22

# Development image with build tools
docker pull ghcr.io/the-mines/sbi/node22-dev
```
<!--getting:end-->

<!--body:start-->
## Compatibility Notes

Where possible, the Node SBI image is built for compatibility with the [Docker official image for Node](https://hub.docker.com/_/node/).

The Node SBI image runs as a nonroot user (`node`) by default. A `USER root` statement may be required before performing tasks requiring elevated permissions.

## Getting Started

### Example: Distroless CLI Application

In this example, we'll write a `.js` script that prints a message, then prints the message reversed. The script will use one dependency, the [`text-reverse`](https://www.npmjs.com/package/text-reverse) package. The script will optionally take one positional argument—if no argument is passed, a default message will be printed and reversed, otherwise the passed argument will be printed and reversed.

First, let's create a project structure for our example:

```sh
mkdir -p ~/node-reverse/bin && cd ~/node-reverse
```

This creates the following folder structure and sets our working directory to the root `node-reverse`folder:

```
node-reverse
└── bin
```

Now let's create a `package.json` file, which provides metadata about the project, including dependencies:

```sh
cat << 'EOF' > package.json
{
    "name": "spellcarver_hello",
    "version": "1.0.0",
    "description": "Say hello to Spellcarver",
    "main": "bin",
    "bin": {
        "spellcarver_hello": "./bin/index.js"
    },
    "keywords": [],
    "author": "",
    "license": "ISC",
    "dependencies": {
        "text-reverse": "^1.0.0"
    }
}
EOF
```

The above defines a package, `spellcarver_hello`, that depends on `text-reverse`, and which whill run the code in `bin/index.js` on `npm run start`.

Let's create our application code now:

```sh
cat << 'EOF' > bin/index.js
#!/usr/bin/env node

const reverse=require('text-reverse');

const run_argument=process.argv[2]

if (run_argument) {
    console.log(run_argument)
    console.log(reverse(run_argument))
} else {
    const message="Hello, Spellcarver!"
    const reversed=reverse(message)
    console.log(message  + "🐙")
    console.log("🐙" + reversed)
}
EOF
```

This application code first looks at any arguments passed to the script. If a positional argument is passed when the script is run, it will print that argument, then print its reverse. If no argument is passed, a default message will be printed and reversed.

Finally, let's create a `Dockerfile` for our image build:

```sh
cat << 'EOF' > Dockerfile
FROM ghcr.io/the-mines/sbi/node22
ENV NODE_ENV=production

WORKDIR /app

COPY --chown=node:node package.json .
ADD ./bin ./bin
RUN npm install

ENTRYPOINT ["node", "bin/index.js"]
EOF
```

This `Dockerfile` sets the `file NODE_ENV` environment variable to `production`, copies our `package.json` and `bin` directory, installs our dependency with `npm install`, and runs our `.js` script.

Build the image, tagging it `node-reverse`:

```sh
docker build . -t node-reverse
```

Finally, run the container:

```sh
docker run node-reverse
```

You should see the following output:

```
Hello, Spellcarver!߷
߷!revracllepS ,olleH
```

You can also pass an argument to the `docker run node-reverse` command to change the output:

```sh
docker run node-reverse "Hello, Spellcarver User\!"
```

This should produce the following output:

```
Hello, Spellcarver User!
!resU revracllepS ,olleH
```

## Example: Express.js Server

In this example, we'll create an [Express.js](https://expressjs.com/) server that allows retrieval of a JSON-formatted list of animals and the addition of new animals via POST request.

First, create a folder for our example:

```sh
mkdir -p ~/node-express && cd $_
```

Create a `package.json` file, which provides metadata about the project, including dependencies:

```sh
cat << 'EOF' > package.json
{
  "name": "Express Server",
  "version": "1.0.0",
  "description": "A server that allows getting and posting dummy data in JSON format",
  "main": "server.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "node server.js"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "body-parser": "^1.14.1",
    "express": "^4.13.3"
  }
}
EOF
```

Next, add our server application code:

```sh
cat << 'EOF' > server.js
var express = require('express');
var bodyParser = require('body-parser');
var app = express();

//Allow all requests from all domains
app.all('/*', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type, Accept");
  res.header("Access-Control-Allow-Methods", "POST, GET");
  next();
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}));

var animals = [
    {
        "id": "234kjw",
        "text": "octopus"
    },
    {
        "id": "as82w",
        "text": "penguin"
    },
    {
        "id": "234sk1",
        "text": "whale"
    }
];


app.get('/animals', function(req, res) {
    console.log("GET From SERVER");
    res.send(animals);
});

app.post('/animals', function(req, res) {
    var animal = req.body;
    console.log(req.body);
    animals.push(animal);
    res.status(200).send("Successfully posted animal\n");
});

console.log("🐙🐧🐋 Server running. Retreive animals from http://localhost:6069/animals")
app.listen(6069);
EOF
```

Finally, create a `Dockerfile` for our image build:

```sh
cat << 'EOF' > Dockerfile
FROM ghcr.io/the-mines/sbi/node22
ENV NODE_ENV=production

WORKDIR /app

COPY --chown=node:node ["package.json", "server.js", "./"]

RUN npm install --omit-dev

CMD [ "server.js" ]
EOF
```

Build the image:

```sh
docker build . -t node-express
```

Finally, run the server container:

```sh
 docker run --rm -p 6069:6069 node-express
```

You should see the following message:

```
🐙🐧🐋 Server running. Retreive animals from http://localhost:6069/animals
```

Visit [http://localhost:6069/animals](http://localhost:6069/animals) to view the served JSON data.

You can post new data to the running application:

```sh
 curl -H 'Content-Type: application/json' \
 -d '{ "id":9001,"text":"gnu"}' \
 -X POST \
 http://localhost:6069/animals
```

After posting, refresh the page on [http://localhost:6069/animals](http://localhost:6069/animals) to view the additional data.

## Documentation and Resources

- [GitHub Repository: Spellcarver Base Images (SBI)](https://github.com/The-Mines/sbi)
- [Node.js Official Documentation](https://nodejs.org/docs/latest-v22.x/api/)
- [Report Issues for SBI Node Image](https://github.com/The-Mines/sbi/issues)
- [Node.js Best Practices for Containers](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)

<!--body:end-->

## Support

For support, please open an issue in the [GitHub repository](https://github.com/The-Mines/sbi/issues).

## What are Spellcarver Base Images?

Spellcarver Base Images (SBI) are a collection of container images designed for security and minimalism.

Many SBI images are distroless; they contain only an open-source application and its runtime dependencies. These images do not even contain a shell or package manager. SBI images are built with [Wolfi](https://github.com/wolfi-dev), a Linux _undistro_ designed to produce container images that meet the requirements of a secure software supply chain.

The main features of SBI images include:

* Minimal design, with no unnecessary software bloat
* Automated nightly builds to ensure Images are completely up-to-date and contain all available security patches
* High quality build-time SBOMs (software bills of materials) attesting the provenance of all artifacts within the Image
* Verifiable signatures provided by [Sigstore](https://www.sigstore.dev/)
* Reproducible builds with Cosign and apko

### `-dev` Variants

As mentioned previously, SBI images have no shell or package manager by default. This is great for security, but sometimes you need these things, especially in builder images. For those cases, most (but not all) SBI images come paired with a `-dev` variant which does include a shell and package manager.

Although the `-dev` image variants have similar security features as their distroless versions, such as complete SBOMs and signatures, they feature additional software that is typically not necessary in production environments. The general recommendation is to use the `-dev` variants only to build the application and then copy all application artifacts into a distroless image, which will result in a final container image that has a minimal attack surface and won't allow package installations or logins.

That being said, it's worth noting that `-dev` variants of SBI images are completely fine to run in production environments. After all, the `-dev` variants are still **more secure** than many popular container images based on fully-featured operating systems such as Debian and Ubuntu since they carry less software, follow a more frequent patch cadence, and offer attestations for what they include.

## Learn More

To better understand how to work with SBI images, we encourage you to visit the [GitHub repository](https://github.com/The-Mines/sbi) for more documentation and examples.