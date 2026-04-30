FROM mcr.microsoft.com/mssql/server:2019-latest

# Switch to root to install packages
USER root

# Suppress interactive prompts during the build
ENV DEBIAN_FRONTEND=noninteractive

# Run your exact setup sequence
RUN apt-get update && \
    apt-get install -yq curl apt-transport-https gnupg && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl -sL https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list | tee /etc/apt/sources.list.d/mssql-server-2019.list && \
    apt-get update && \
    apt-get install -y mssql-server-fts && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to the standard mssql user for security
USER mssql