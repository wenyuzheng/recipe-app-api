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
# Line 1: creates a virtual env which is a safe guard to reduce the risk of python dependencies on the actual base image conflicting with the dependencies of the project.
# Line 2: upgrade the python package manager pip inside the virtual env (as we specifed the full path to the pip inside the venv)
# Line 3: install the list of requirements inside vitual env
# Line 4: if dev is true, install the dev requirements list in venv
# Line 7: remove the tmp directory becasue we don't want extra dependecies => keep the docer image lightweight
# Line 8: add a new user to docker image to avoid using the root user, no-create-home is bot to create a home directory => lightweight, django-user is the name of the user
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# Updates the env variable in the image so we don't have to specify the venv everytime we run the command, PATH is the env var that auto created on Linux os
ENV PATH="/py/bin:$PATH"

# This is to switch to the django-user, before getting to this line, all commands are done by root user
USER django-user