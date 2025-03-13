# ───────────────────────────────────────────────────────────
# 🏗️ Stage 1: Build the Node.js application
# ───────────────────────────────────────────────────────────
FROM node:22-alpine AS builder
# Install dependencies
RUN apk add --no-cache tzdata
# Set timezone to Asia/Bangkok
ENV TZ=Asia/Bangkok
# Set up working directory
WORKDIR /app
# Install pnpm globally
RUN npm install -g pnpm
# Copy package files first to cache dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
# Copy the entire source code
COPY . .
# Build the application
RUN pnpm run build

# ───────────────────────────────────────────────────────────
# 🚀 Stage 2: Create the final runtime image
# ───────────────────────────────────────────────────────────
FROM node:22-alpine AS runner
# Install necessary system packages
RUN apk --no-cache add ca-certificates tzdata
# Set timezone to Asia/Bangkok
ENV TZ=Asia/Bangkok
# Set up working directory
WORKDIR /app
# Install pnpm globally in the runner stage
RUN npm install -g pnpm
# Copy package files and install production dependencies only
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./
RUN pnpm install --prod
# Copy necessary project files from builder
COPY --from=builder /app/next.config.ts ./
COPY --from=builder /app/.next ./.next
# Set environment to production
ENV NODE_ENV=production
# Cloud Run requires the app to listen on $PORT, default to 3000
ENV PORT=3000
# Expose the port (for documentation, Cloud Run ignores it)
EXPOSE 3000
# Start the Node.js application
CMD ["pnpm", "start"]