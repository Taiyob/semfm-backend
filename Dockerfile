# Stage 1: Build stage
FROM oven/bun:1.3.10 AS builder
WORKDIR /app

# ১. শুধুমাত্র প্রয়োজনীয় ফাইলগুলো কপি করুন ভালো ক্যাশিংয়ের জন্য
COPY package.json bun.lock prisma.config.ts ./
COPY src/prisma ./src/prisma/

# ২. সব প্যাকেজ ইন্সটল করুন (devDependencies সহ) এবং ক্লায়েন্ট জেনারেট করুন
RUN bun install --frozen-lockfile
RUN bun run db:generate

# ৩. সোর্স কোড কপি করুন
COPY . .

# ৪. প্রজেক্ট বিল্ড করুন
RUN bun run build

# Stage 2: Production stage (Slim image for smaller size)
FROM oven/bun:1.3.10-slim AS runner
WORKDIR /app

ENV NODE_ENV=production

# ৫. বিল্ডার থেকে শুধু প্রয়োজনীয় ফাইলগুলো নিয়ে আসুন
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
# Prisma এর জেনারেটেড ফাইলগুলো সোর্স ডিরেক্টরিতে থাকে, তাই তা কপি করতে হবে
COPY --from=builder /app/src/generated ./src/generated 

EXPOSE 3030

CMD ["bun", "dist/index.js"]