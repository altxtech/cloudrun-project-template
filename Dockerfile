# Use the official Go base image for your Go version
FROM golang:1.21 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the Go source code into the container
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux go build -o app

# Use a smaller base image to create the final image
FROM alpine:latest

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled Go application from the build image
COPY --from=build /app/app .

# Expose the port that your Go application listens on
EXPOSE 8080

# Define the command to run your Go application
CMD ["./app"]

