FROM debian:stable
LABEL authors="greg-ogs"
# Flask app

WORKDIR /app

EXPOSE 80

RUN apt update && apt install --upgrade git -y && apt install --upgrade python3 -y && apt install python3.11-venv -y \
    && apt install curl -y && apt install unzip -y && apt install python3-pip -y && python3 -m venv main

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && apt-get update -y && apt-get install google-cloud-cli -y

COPY entrypoint.sh .

RUN git clone https://github.com/GoogleCloudPlatform/python-docs-samples  && \
    cd /app/python-docs-samples/cloud-sql/mysql/sqlalchemy && \
    /app/main/bin/pip install -r requirements.txt

ENTRYPOINT ["./entrypoint.sh"]

CMD ["flask", "run", "--host=0.0.0.0", "--port=80"]

#docker build -t your-image-name .
#docker run -p 80:80 -e INSTANCE_CONNECTION_NAME="your-project:your-region:your-instance" db_credentials=<> your-image-name
