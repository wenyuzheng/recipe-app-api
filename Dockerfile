# The Dockerfile is used to build our image, which contains a mini Linux Operating System with all the dependencies needed to run our project.

# FROM: the base image, versions can be found on docker website
# maintainer is the maintainer of this projet, could sepcify your name or website
FROM python:3.9-alpine3.13
LABEL maintainer="wenyuz.com"

# Tells Python not to buffer the output, i.e. should print the logs immediately as they are running
ENV PYTHONUNBUFFERED 1

# COPY A B: copies the file A from this directory to B in Docker container
# WORKIDR: the default directory that the commande will be run from when running commands on Docker image, so no need to specify the full path
# EXPOSE: expose port 8000 from container to our machine, allows access to the port on the container, this is the way to connect Django development server.
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
COPY ./app /app
WORKDIR /app
EXPOSE 8000

# Defines a build argument called DEV and sets the default value to false, which is then override iside docker-compose.yml file
ARG DEV=false
# This is a single RUN block, although could add RUN command in front of each line, but then each command will create a new image layer. Therefore we want to avoid multiple commands to keep the image as lightweight as possible so that image building is more efficient, and thus break each line using the syntax `&& \`.
# venv line: creates a virtual env which is a safe guard to reduce the risk of python dependencies on the actual base image conflicting with the dependencies of the project.
# upgrade pip line: upgrade the python package manager pip inside the virtual env (as we specifed the full path to the pip inside the venv)
# apk add postgresql-client: install postgresql-client inside our alpine image
# apk add tmp-build-deps: sets a virtual dependency package into tmp-build-deps, below this line is the list of packages we want to install for installing postgres adaptor
# pip install line: install the list of requirements inside vitual env
# if block: if dev is true, install the dev requirements list in venv
# rm tmp line: remove the tmp directory becasue we don't want extra dependecies => keep the docer image lightweight
# apk del: renove the packages in tmp-build-deps because they are only needed to install postgres adaptor not needed for development
# adduser line: add a new user to docker image to avoid using the root user, no-create-home is bot to create a home directory => lightweight, django-user is the name of the user
# mkdir -p lines: create these two directories if they do not exist
# chown line: change the owner of the directories and subdirectories of /vol to be django-user
# chmod line: change mode i.e. give permission to django-user to make any changes to /vol
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user && \
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /vol && \
    chmod -R 755 /vol

# Updates the env variable in the image so we don't have to specify the venv everytime we run the command, PATH is the env var that auto created on Linux os
ENV PATH="/py/bin:$PATH"

# This is to switch to the django-user, before getting to this line, all commands are done by root user
USER django-user