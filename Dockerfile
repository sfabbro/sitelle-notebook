FROM jupyter/scipy-notebook:latest

LABEL maintainer="CANFAR Project <support@canfar.net>"

USER root
WORKDIR /tmp

# update base
RUN apt-get update --yes --quiet --fix-missing \
    && apt-get upgrade --yes --quiet

# install bunch of packages
COPY packages.apt .
RUN apt-get install --yes --quiet $(cat packages.apt)
RUN apt-get clean --yes \
    && apt-get autoremove --purge --quiet --yes \
    && rm -rf /var/lib/apt/lists/* /var/tmp/*

# install latest stilts
RUN wget --quiet http://www.star.bris.ac.uk/~mbt/stilts/stilts.jar -O /usr/local/bin/stilts.jar \
    && wget --quiet http://www.star.bris.ac.uk/~mbt/stilts/stilts -O /usr/local/bin/stilts \
    && chmod +x /usr/local/bin/stilts

# install topcat with parquet
RUN wget --quiet http://www.star.bris.ac.uk/~mbt/topcat/topcat-extra.jar -O /usr/local/bin/topcat-extra.jar \
    && wget --quiet http://www.star.bris.ac.uk/~mbt/topcat/topcat -O /usr/local/bin/topcat \
    && sed -i -e 's/topcat-full/topcat-extra/g' /usr/local/bin/topcat \
    && chmod +x /usr/local/bin/topcat

# nsswitch for correct sss lookup
ADD nsswitch.conf /etc/

# modify basic environment from jupyter/scipy-notebook
ENV CONDA_OVERRIDE_CUDA=""
COPY env.yml .

USER ${NB_USER}

# use blas MKL rather than openblas
RUN mamba remove nomkl --yes
RUN rm ${CONDA_DIR}/conda-meta/pinned

RUN mamba env update --quiet -n base --file env.yml \
    && mamba update --quiet --all --yes \
    && mamba clean --all --quiet --force --yes \
    && jupyter lab build \
    && fix-permissions ${CONDA_DIR} \
    && fix-permissions /home/${NB_USER}

USER root
ADD pinned ${CONDA_DIR}/conda-meta/pinned
COPY condarc .
RUN cat condarc >> ${CONDA_DIR}/.condarc
RUN fix-permissions ${CONDA_DIR}

RUN npm cache clean --force \
    && jupyter lab clean \
    && rm -rf /home/${NB_USER}/.cache/*

# orbs & orcs (dependencies in env.yml)
RUN pip install --no-cache \
    git+https://github.com/thomasorb/orb.git \
    git+https://github.com/thomasorb/orcs.git

WORKDIR ${HOME}
