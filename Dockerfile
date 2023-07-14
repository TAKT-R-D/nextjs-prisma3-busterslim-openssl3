FROM node:18.16.1-buster-slim AS base

FROM base AS deps
# install openssl3.0.8
RUN apt-get update && apt-get install wget build-essential zlib1g-dev make -y

WORKDIR /usr/local/src
RUN wget https://www.openssl.org/source/openssl-3.0.8.tar.gz
RUN tar -zxf /usr/local/src/openssl-3.0.8.tar.gz

WORKDIR /usr/local/src/openssl-3.0.8
RUN ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib
RUN make && make install

# Install dependencies based on the preferred package manager
WORKDIR /app
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# build
FROM base AS builder
COPY --from=deps /usr/local/ssl /usr/local/ssl
RUN echo "/usr/local/ssl/lib\n/usr/local/ssl/lib64" > /etc/ld.so.conf.d/openssl-3.0.8.conf && ldconfig
ENV PATH="$PATH:/usr/local/ssl/bin"


WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1

RUN npx prisma generate
RUN yarn build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN groupadd -g 1001 -r nodejs
RUN adduser --system nextjs --uid 1001

COPY --from=builder /app/public ./public

COPY --from=builder /usr/local/ssl /usr/local/ssl
COPY --from=builder /etc/ld.so.conf.d/openssl-3.0.8.conf /etc/ld.so.conf.d/openssl-3.0.8.conf
RUN ldconfig
ENV PATH="$PATH:/usr/local/ssl/bin"

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --chown=nextjs:nodejs prisma ./prisma/

USER nextjs

EXPOSE 8080

ENV PORT 8080

CMD ["node", "server.js"]
