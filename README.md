# one-chat

## How to create a new React application with GitOps for K8s

### A: Basic setup

1. Create a new application in this case using `vite`: `npm create vite@latest` using the option for `React` + `Typescript`.

2. Instead of Docker we are going to use [Buildpacks](https://paketo.io/docs/) - as a prereq assuming you have Docker installed you just need the [pack cli](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/) and
  
- run the command `pack build one-chat --buildpack paketo-buildpacks/nodejs --builder paketobuildpacks/builder-jammy-base` to test the build pack
- when we need to build and cache this on an ECR `--publish 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest --cache-image 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest`

I played around with some other options see `repack.sh`

3. `npm i & npm run dev`

Without worrying about Argo, a simple deployment that you can deploy and test on a K8s cluster is in `/app/manifest/deployment.yaml`. you can use kube-forwarder to open a port to the deployment to test the app.

### B: Now that we have a basic application we can test the deployments

We can warp our deployment as an Argo Application that can be deployed into multiple clusters. In a later step we will create git actions to build that container so the app can be synced.

We start by configuring our git-repo to talk to Argo. In this case I am in the one-chat repo and i can connect Argo to it. I added a [deploy key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys) by generating a key, pasting the public part into a new deploy key and holding onto the private key for adding the repo in ArgoCD. Note, git asks us to generate keys like this

```bash
ssh-keygen -t ed25519 -C "techpirates@resonance.nyc"
```

The Argo-CD part is done in Settings->Repositories->Add Repository Using SSh -> and pasting in the full private key and the git+ssh url for the repository. Here is the [argo dev link](https://argocddev.resmagic.io/settings/repos) as an example where you can add your own repository

Now that we have added our repo, we can add an Argo-CD application. I have illustrated how the argo application is created declaratively in the `.argo-cd` folder. The basic configuration is very easy and merely points to the the git repository where our Kustomize application lives. This Kustomize is just a simple wrapper around our simple deployment to allow for bundling multiple resources (in this case just one) and also doing some simple build time parameterization. Our main reason for using it here is its one of the main types that Argo supports.

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
