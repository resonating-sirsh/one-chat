# one-chat

## How to create a new React application with GitOps for K8s

### A: Basic setup

1. Create a new application in this case using `vite`: `npm create vite@latest` using the option for `React` + `Typescript`.

2. Instead of Docker we are going to use [Buildpacks](https://paketo.io/docs/) - as a prereq assuming you have Docker installed you just need the [pack cli](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/) and
  
- run the command `pack build one-chat --buildpack paketo-buildpacks/nodejs --builder paketobuildpacks/builder-jammy-base` to test the build pack
- when we need to build and cache this on an ECR `--publish 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest --cache-image 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest`

I played around with some other options see `repack.sh`

3. `npm i & npm run dev`

### B: Now that we have a basic application we can test the deployments

We will start with an Argo Application that can be deployed into multiple clusters. The application will run the container image generated and placed on ECR above which contains our application. In a later step we will create git actions to build that container so the app can be synced

### C: git actions to build the app and sync to cluster(s)

# Notes

TODO (Research platform builds for node) Issue: <https://github.com/npm/cli/issues/4828>

- i made one override to allow me to install locally while also building buildpack

```bash
 "overrides": {
    "vite": {
      "rollup": "npm:@rollup/wasm-node"
    }
  },
```

- you need to login to build and push to ECR `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 286292902993.dkr.ecr.us-east-1.amazonaws.com`

- Why build packs
<https://blog.logrocket.com/dockerize-node-js-apps-buildpacks/>
<https://stackoverflow.com/questions/68770567/containerizing-angular-application-with-paketo-buildpacks-empty-reply>
