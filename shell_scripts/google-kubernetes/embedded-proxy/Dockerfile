FROM debian:stable
LABEL authors="grego"

WORKDIR /app

EXPOSE 8080 3306

RUN apt update && apt install --upgrade git -y && apt install --upgrade python3 -y && apt install python3.11-venv -y \
    && apt install curl -y && apt install unzip -y && apt install python3-pip -y && python3 -m venv main

COPY entrypoint.sh .

RUN curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.15.2/cloud-sql-proxy.linux.amd64 && \
    chmod +x cloud-sql-proxy && chmod +x entrypoint.sh

RUN git clone https://github.com/GoogleCloudPlatform/python-docs-samples  && \
    cd /app/python-docs-samples/cloud-sql/mysql/sqlalchemy && \
    /app/main/bin/pip install -r requirements.txt

ENTRYPOINT ["./entrypoint.sh"]

CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]

#docker build -t your-image-name .
#docker run -p 8080:8080 -p 3306:3306 -e INSTANCE_CONNECTION_NAME="your-project:your-region:your-instance" your-image-name
