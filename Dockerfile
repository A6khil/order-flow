# Order Flow in a container: builds the page, then serves page + API from server/index.mjs.
#
#   docker build -t order-flow --build-arg MF_BASE_PATH=/orderflow --build-arg VITE_HOME_URL=/ .
#   docker run -p 8787:8787 -e MF_PROVIDER=demo order-flow
#
# The server needs Node >= 22.18 (it imports src/lib/marketSession.ts directly) and
# no npm packages at run time, so the final image carries only what it serves.
ARG NODE_IMAGE=node:22.22-bookworm-slim

FROM ${NODE_IMAGE} AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
# Build-time page settings: the path it is served under and an optional link back to a host app.
ARG MF_BASE_PATH=
ARG VITE_HOME_URL=
ARG VITE_HOME_LABEL=
ENV MF_BASE_PATH="${MF_BASE_PATH}" VITE_HOME_URL="${VITE_HOME_URL}" VITE_HOME_LABEL="${VITE_HOME_LABEL}"
RUN npm run build && cp LICENSE dist/LICENSE.txt && cp NOTICE.md dist/NOTICE.md

FROM ${NODE_IMAGE}
ENV NODE_ENV=production HOST=0.0.0.0 PORT=8787 MF_DATA_DIR=/data TZ=Asia/Kolkata
WORKDIR /app
COPY --from=build /src/package.json /src/LICENSE /src/NOTICE.md ./
COPY --from=build /src/server ./server
COPY --from=build /src/src/lib/marketSession.ts ./src/lib/marketSession.ts
COPY --from=build /src/public ./public
COPY --from=build /src/data ./data
COPY --from=build /src/examples ./examples
COPY --from=build /src/dist ./dist
ARG MF_BASE_PATH=
ENV MF_BASE_PATH=${MF_BASE_PATH}
RUN mkdir -p /data && chown node:node /data
USER node
EXPOSE 8787
CMD ["node", "server/index.mjs"]
