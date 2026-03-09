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

RUN wget -O pose_landmarker.task https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task

ENTRYPOINT ["conda", "run", "--no-capture-output", "--name", "ascension-ai", "python", "-u", "consumer.py"]
