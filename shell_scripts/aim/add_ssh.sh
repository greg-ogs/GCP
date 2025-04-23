#!/bin/bash

gcloud compute os-login ssh-keys list

gcloud compute os-login ssh-keys add --key-file=/home/greg-ogs/.ssh/id_rsa.pub --project=$(gcloud config get-value project)