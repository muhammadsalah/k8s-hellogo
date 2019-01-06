all: build

build: main.go
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bin/hellogo
docker:
	docker build -t hellogo:${IMAGE_VERSION} .
clean:
	rm -r bin/hellogo