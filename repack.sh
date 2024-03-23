export DOCKER_DEFAULT_PLATFORM=linux/amd64/v8

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 286292902993.dkr.ecr.us-east-1.amazonaws.com
 
pack build --buildpack paketo-buildpacks/web-servers \
--env "BP_WEB_SERVER=nginx" \
--env "BP_WEB_SERVER_ROOT=dist" \
--env "BP_WEB_SERVER_ENABLE_PUSH_STATE=true" \
--env "NODE_ENV=production"\
--cache-image 286292902993.dkr.ecr.us-east-1.amazonaws.com/infra-test:one-chat-latest --publish
