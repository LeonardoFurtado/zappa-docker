FROM python:3.8 as base

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

FROM base AS python-deps

# Install pipenv and compilation dependencies
RUN pip install pipenv
RUN python -m pip install --upgrade pip
RUN apt-get update && apt-get install -y --no-install-recommends gcc

RUN apt-get install postgresql-client libjpeg-dev -y

RUN apt-get install gcc libc-dev musl-dev zlib1g zlib1g-dev -y

# Install python dependencies in /.venv
COPY Pipfile .
COPY Pipfile.lock .
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy
#RUN apk del .tmp-build-deps


FROM base AS runtime

# Copy virtual env from python-deps stage
COPY --from=python-deps /.venv /.venv
ENV PATH="/.venv/bin:$PATH"

COPY . .

ARG FUNCTION_DIR="/var/task/"

COPY ./ $FUNCTION_DIR

# Grab the zappa handler.py and put it in the working directory
RUN ZAPPA_HANDLER_PATH=$( \
    python -c "from zappa import handler; print (handler.__file__)" \
    ) \
    && echo $ZAPPA_HANDLER_PATH \
    && cp $ZAPPA_HANDLER_PATH $FUNCTION_DIR

CMD ["handler.lambda_handler"]
