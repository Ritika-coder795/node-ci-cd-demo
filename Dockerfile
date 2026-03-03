# -------- Stage 1: Builder --------
FROM node:18-alpine AS builder

WORKDIR /app

# Add metadata
LABEL stage="builder"

# Copy only package files first (better layer caching)
COPY package*.json ./

# Use npm ci for clean, reproducible install
RUN npm ci

# Copy source code
COPY . .

# Run tests (CI will fail if tests fail)



# -------- Stage 2: Production --------
FROM node:18-alpine

# Add metadata labels (Industry Best Practice)
LABEL maintainer="Mritika Kumbar"
LABEL application="node-ci-cd-demo"
LABEL environment="production"

WORKDIR /app

# Copy package files again
COPY package*.json ./

# Install ONLY production dependencies
RUN npm ci --omit=dev

# Copy app from builder stage
COPY --from=builder /app .

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

USER appuser

# Expose port
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --spider http://localhost:3000/health || exit 1

CMD ["node", "app.js"]
