FROM arhodes77/rnaseq-trinity:dsl2
LABEL authors="Arhodes updates, Phil Ewels, Rickard Hammarén" \
      description="Docker image containing all software requirements for TransLig assembly"

# Install the conda environment
COPY environment.yml /
RUN conda env create --quiet -f /environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/nf-core-rnaseq-1.4.3dev/bin:$PATH
# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nf-core-rnaseq-1.4.3dev > nf-core-rnaseq-1.4.3dev.yml

# Instruct R processes to use these empty files instead of clashing with a local version
RUN touch .Rprofile
RUN touch .Renviron

#Add custom scripts
RUN mkdir -p /scripts
COPY *.sh /scripts
WORKDIR /scripts
RUN chmod +x *.sh

