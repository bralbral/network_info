FROM python:3.12-slim
LABEL maintainer="Denis Kosyakov  <bralbral@gmail.com>"

RUN useradd -m -d /app app

WORKDIR /app

COPY requirements.txt /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    wget \
    libpq-dev \
    gcc \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get remove -y gcc libpq-dev \
    && apt-get autoremove -y \
    && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY . /app
RUN chown -R app:app /app
USER app

RUN mkdir -p databases

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["--help"]
