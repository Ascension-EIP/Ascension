FROM continuumio/miniconda3

WORKDIR /app

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libgl1 \
		libglib2.0-0 \
	&& rm -rf /var/lib/apt/lists/*

# Create the environment:
COPY . .

RUN conda env create -n ascension-ai -f environment.yml

RUN conda run --name ascension-ai pip install -e .

ENTRYPOINT ["conda", "run", "--no-capture-output", "--name", "ascension-ai", "python", "-u", "consumer.py"]
