# Day 26 - Containerization with Docker Fundamentals

## Objective

Master Docker containerization concepts and practical skills for creating, managing, and orchestrating containers to build portable and scalable applications.

---

## What I Learned

### 1. Container Concepts

- **Containers vs VMs**: Lightweight isolation using shared kernel vs full virtualization
- **Docker Architecture**: Client-server model with daemon, REST API, and CLI
- **Images vs Containers**: Immutable templates (images) vs running instances (containers)
- **Layered File System**: Union file system with read-only layers and writable container layer
- **Container Lifecycle**: Create → Start → Run → Stop → Remove

### 2. Docker Commands Fundamentals

#### Image Management
```bash
# Search for images
docker search nginx

# Pull images from registry
docker pull ubuntu:22.04

# List local images
docker images

# Remove images
docker rmi image_name
```

#### Container Operations
```bash
# Run container interactively
docker run -it ubuntu bash

# Run container in background
docker run -d --name webserver nginx

# List running containers
docker ps

# List all containers
docker ps -a

# Stop and remove containers
docker stop container_name
docker rm container_name
```

### 3. Dockerfile Creation

#### Multi-stage Builds
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Optimization Techniques
- **Layer Caching**: Order instructions from least to most frequently changing
- **.dockerignore**: Exclude unnecessary files from build context
- **Minimal Base Images**: Use alpine or distroless for smaller images
- **Multi-stage Builds**: Separate build and runtime environments

### 4. Volume Management

#### Bind Mounts vs Volumes
```bash
# Bind mount - host directory mapped to container
docker run -v /host/path:/container/path nginx

# Named volume - managed by Docker
docker run -v data_volume:/container/path nginx

# Anonymous volume - temporary storage
docker run -v /container/path nginx
```

#### Volume Operations
```bash
# Create volume
docker volume create mydata

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Remove volume
docker volume rm mydata
```

### 5. Networking

#### Network Types
- **Bridge**: Default isolated network for containers
- **Host**: Container shares host's network stack
- **Overlay**: Multi-host networking for Swarm
- **None**: No network connectivity

#### Network Commands
```bash
# Create custom network
docker network create myapp_net

# Connect container to network
docker network connect myapp_net container_name

# List networks
docker network ls

# Inspect network
docker network inspect myapp_net
```

---

## What I Built / Practiced

### Web Application Stack
- **Nginx Reverse Proxy**: Load balancing and SSL termination
- **Node.js Backend**: RESTful API with database connectivity
- **PostgreSQL Database**: Persistent data storage with volumes
- **Redis Cache**: In-memory caching for performance

### Development Environment
- **Multi-container Setup**: Coordinated development environment
- **Hot Reloading**: Live code changes without container rebuilds
- **Service Discovery**: Automatic container registration and discovery
- **Health Checks**: Automated service monitoring and recovery

### CI/CD Pipeline
- **Automated Builds**: GitHub Actions for Docker image creation
- **Image Registry**: Private registry for storing custom images
- **Deployment Automation**: Zero-downtime rolling updates
- **Environment Management**: Separate configs for dev/staging/prod

---

## Challenges Faced

- **Image Size Bloat**: Initial images were 1GB+ - learned optimization techniques to reduce to <100MB
- **Permission Issues**: Container user permissions vs host file system - solved with proper user mapping
- **Data Persistence**: Losing data on container restart - implemented proper volume strategies
- **Network Isolation**: Services couldn't communicate - configured custom networks and service discovery
- **Build Performance**: Slow rebuilds on code changes - optimized Dockerfile layering and caching

---

## Key Takeaways

- **Containers are not VMs**: Shared kernel makes them lightweight and fast
- **Immutable Infrastructure**: Treat containers as cattle, not pets - replace rather than modify
- **Layer Caching Matters**: Proper Dockerfile ordering dramatically speeds up builds
- **Volumes are Essential**: Persistent data must live outside containers
- **Security by Default**: Run as non-root, limit capabilities, use minimal base images
- **Networking is Powerful**: Custom networks provide isolation and service discovery
- **Multi-stage Builds**: Separate build and runtime for smaller, more secure images

---

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Container Security Guide](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

---

## Output

### Docker Compose Stack (`docker-compose.yml`)
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
    networks:
      - appnet

  backend:
    build: ./backend
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/app
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    networks:
      - appnet

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - appnet

  redis:
    image: redis:7-alpine
    volumes:
      - redisdata:/data
    networks:
      - appnet

volumes:
  pgdata:
  redisdata:

networks:
  appnet:
    driver: bridge
```

### Optimized Dockerfile (`backend/Dockerfile`)
```dockerfile
# Multi-stage build for Node.js application
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runtime
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

USER nextjs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

### Development Environment Script (`dev.sh`)
```bash
#!/bin/bash
# Development environment launcher

echo "Starting development environment..."

# Create network if not exists
docker network inspect devnet >/dev/null 2>&1 || docker network create devnet

# Start database
docker run -d --name dev-db \
  --network devnet \
  -e POSTGRES_DB=devapp \
  -e POSTGRES_USER=dev \
  -e POSTGRES_PASSWORD=devpass \
  -v devdata:/var/lib/postgresql/data \
  postgres:15-alpine

# Start Redis
docker run -d --name dev-redis \
  --network devnet \
  -v redisdata:/data \
  redis:7-alpine

# Start backend with hot reload
docker run -d --name dev-backend \
  --network devnet \
  -v $(pwd)/backend:/app \
  -w /app \
  -p 3000:3000 \
  node:18-alpine \
  npm run dev

echo "Development environment ready!"
echo "Backend: http://localhost:3000"
echo "Database: postgresql://dev:devpass@localhost:5432/devapp"
```

### Production Deployment Script (`deploy.sh`)
```bash
#!/bin/bash
# Production deployment with zero downtime

set -euo pipefail

IMAGE_TAG="v$(date +%Y%m%d_%H%M%S)"
REGISTRY="myregistry.com"

echo "Building and deploying version: $IMAGE_TAG"

# Build new image
docker build -t $REGISTRY/myapp:$IMAGE_TAG .
docker push $REGISTRY/myapp:$IMAGE_TAG

# Update production service
docker service update \
  --image $REGISTRY/myapp:$IMAGE_TAG \
  --update-parallelism 1 \
  --update-delay 10s \
  myapp_service

echo "Deployment initiated. Monitoring rollout..."
docker service logs -f myapp_service
```
