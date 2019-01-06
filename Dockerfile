FROM golang as build

WORKDIR /go/src/app

COPY . .

RUN go get -d -v

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o hellogo

FROM alpine

WORKDIR /app

COPY --from=build /go/src/app/hellogo /app/hellogo

CMD ["/app/hellogo"]