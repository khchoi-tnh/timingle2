#!/bin/bash
export PATH=/usr/local/go/bin:$PATH
cd /root/projects/timingle2/backend
go mod tidy
go build -o bin/api cmd/api/main.go
echo "Build complete: bin/api"
ls -la bin/
