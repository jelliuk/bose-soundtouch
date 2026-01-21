FROM node:18-alpine

# Install git
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/vintx86/bose-soundtouch.git .

# Install dependencies
RUN npm install

# Expose port if your app serves HTTP
EXPOSE 8090

# Expose volume for bind/mount
VOLUME /app

# Default command - you'll likely want to override this
# with your own script or command
CMD ["npm", "run", "start"]
