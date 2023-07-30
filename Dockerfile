# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY ./src /app

# Install Flask
RUN pip install Flask

# Make port 8080 available to the world outside this container
EXPOSE 80

# Run app.py when the container launches
CMD ["python", "app.py"]