# one-chat

## How to create a new React application with GitOps for K8s

### A: Basic setup

1. Create a new application in this case using `vite` using `npm create vite@latest` using the option for `React` and `Typescript`.

2. Instead of Docker we are going to use [Buildpacks](https://paketo.io/docs/). As a prereq, assuming you have Docker installed, you just need the [pack cli](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/) and then
  
- run the command `pack build one-chat --buildpack paketo-buildpacks/nodejs --builder paketobuildpacks/builder-jammy-base` to test the build pack
- and when we need to build and cache this on an ECR `--publish 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest --cache-image 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest`

I played around with some other options see `repack.sh`

For local dev then,
3. `npm i & npm run dev`

Without worrying about Argo, a simple deployment that you can deploy and test on a K8s cluster is in `/app/manifest/deployment.yaml`. This can be deployed with kubectl as per the comments. You can use kube-forwarder to open a port to the deployment to test the app once deployed.

### B: Now that we have a basic application we can test the deployment via Argo-CD

We can wrap our deployment as an Argo Application that can be deployed into multiple clusters. In a later step we will create git actions to build that container so the app can be synced.

We start by configuring our git-repo to talk to Argo. In this case I am in the one-chat repo and i can connect Argo to it. I added a [deploy key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys) by generating a key, pasting the public part into a new deploy key and holding onto the private key for adding the repo in ArgoCD. Note, git asks us to generate keys like this

```bash
ssh-keygen -t ed25519 -C "techpirates@resonance.nyc"
```

The Argo-CD repor set up is done in Settings->Repositories->Add Repository Using SSh -> and pasting in the full private key and the git+ssh url for the repository. Here is the [argo dev link](https://argocddev.resmagic.io/settings/repos) as an example where you can add your own repository

Now that we have added our repo, we can add an Argo-CD application. I have illustrated how the argo application is created declaratively in the `.argo-cd` folder. The basic configuration is very easy and merely points to the the git repository where our Kustomize application lives (this repo in this case). With in the application manifest folder, the Kustomize application is just a simple wrapper around our simple deployment to allow for bundling multiple resources (in this case just one) and also doing some simple build time parameterization. Our main reason for using Kustomize here is its one of the main types that Argo supports.

**Note**: Please review the simple folder structure and files of `app/manifest` to understand what the application we are deploying is.

An Argo Application is application ovject that points to or deploys an application that you defined. You can create this by running the following (with kubectl installed). This is a one time application creation. Argo-CD will then watch our git repository for changes to the source so that we can keep our application in sync on the cluster!!

```bash
#This is added into the default namespace for Argo Application.
#please review the contents of this file
kubectl apply - f ./.argo-cd/application.yaml 
```

Now browse to the cluster/argo-cd e.g. on dev to see that the application is deployed and in sync with our repo. You can search for `one-chat` in this case in [Argo-CD UI](https://argocddev.resmagic.io/applications)

You can test making a change e.g. change the number of replicas in the the deployment pushing it to the main branch (we have not set up separate branches in this repo at the time of writing) and waiting for argo to sync (it does so every three minutes if we don't intervene). There are hooks we can add to optimize this when we complete our GitOps flow later.

### C: Git Actions to build the app and sync to cluster(s)

Finally we can create a simple workflow to build the containers with our code when merged into main. To do this we add a git action to build the container and tag it in the kubernetes application manifest.

- We add a folder `.github/workflows` and place in an `action.yaml` to watch our app deployment

- On the Git repo we should add secrets for AWS keys. (See the Action.yaml for the keys that are used and use secrets manager for the values.)

One thing we can do is tag our container images with `${{ github.sha }}` but semantic version is probably nicer. We also want to run the kustomize to set this tag (this can all be seen in the steps of the `action.yaml`)

#### Kustomize

I added steps in the action to install kustomize and set the image tag. To do this we need to (a little unsatisfying) commit the update Kustomize file back the main branch so ArgoCD can see something changed in our image - namely the container version. I thus allow github actions read-write permissions. You will see the message `k8s github action CI: update image tag to b62cfa7` as the last commit and you will see that kustomization file has this latest image tag. If you wait a minute, you will also see that Argo-CD sync and updates the application with our changes. If testing with just changing Kubernetes attributes such as the number of replicas you will see these reflected in the AgoCD UI. If making changes to the front-end app itself you should see those changes there.

#### Semantic versioning

TODO

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

## image tags

ECR contains the image tags. in this case i used one tag `infra-test` and then created `app-name-git-sha` as the image tag. This was just for demonstration purposes. You can check the image tag in three places; (1) the tags in ECR (2) the commit messages and the kustomize file in the gut repo and (3) the manifest files in kubernetes after they are deployed (e.g. check them in the Argo-CD UI).
